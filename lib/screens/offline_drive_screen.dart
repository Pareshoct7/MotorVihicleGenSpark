import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../services/offline_drive_service.dart';
import 'pdf_viewer_screen.dart';

class OfflineDriveScreen extends StatefulWidget {
  final Directory? initialDirectory;

  const OfflineDriveScreen({super.key, this.initialDirectory});

  @override
  State<OfflineDriveScreen> createState() => _OfflineDriveScreenState();
}

class _OfflineDriveScreenState extends State<OfflineDriveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late List<Animation<double>> _staggeredAnimations;

  Directory? _currentDir;
  List<FileSystemEntity> _contents = [];
  bool _isLoading = true;
  bool _isBackfilling = false;

  // Selection state
  bool _isSelectionMode = false;
  Set<String> _selectedPaths = {};

  // Search and Sort state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'date', 'type'
  bool _sortAscending = true;
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeDirectory();
  }

  void _initAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _staggeredAnimations = List.generate(
      20,
      (index) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          0.1 + (index * 0.03),
          0.6 + (index * 0.03),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _entranceController.forward();
  }

  Future<void> _initializeDirectory() async {
    final rootDir =
        widget.initialDirectory ?? await OfflineDriveService.getRootDirectory();
    if (mounted) {
      setState(() {
        _currentDir = rootDir;
      });
      _loadContents();
    }
  }

  Future<void> _loadContents() async {
    final currentDir = _currentDir;
    if (currentDir == null) return;

    setState(() => _isLoading = true);
    try {
      final rootDir = await OfflineDriveService.getRootDirectory();
      if (rootDir.path == currentDir.path) {
        await OfflineDriveService.syncStructure();
      }
      final items = await OfflineDriveService.getContents(currentDir);
      if (mounted) {
        setState(() {
          _contents = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading folder: $e')));
      }
    }
  }

  void _enterSelectionMode(String path) {
    setState(() {
      _isSelectionMode = true;
      _selectedPaths = {path};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths = _contents.map((e) => e.path).toSet();
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                color: Color(0xFFFF5252),
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                'DELETE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Permanently delete ${_selectedPaths.length} items from the system? This action is irreversible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('ABORT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('DELETE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      for (final path in _selectedPaths) {
        final entity = _contents.firstWhere((e) => e.path == path);
        await OfflineDriveService.deleteFileOrFolder(entity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${_selectedPaths.length} item(s)')),
        );
        _exitSelectionMode();
        _loadContents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _shareSelected() async {
    if (_selectedPaths.isEmpty) return;

    List<XFile> files = [];
    for (var path in _selectedPaths) {
      if (await File(path).exists()) {
        files.add(XFile(path));
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
      _exitSelectionMode();
    }
  }

  Future<void> _zipAndShareSelected() async {
    if (_selectedPaths.length != 1) return;
    final path = _selectedPaths.first;
    final dir = Directory(path);

    if (await dir.exists()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compressing folder...')),
        );

        await OfflineDriveService.zipAndShareFolder(dir);
        _exitSelectionMode();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing folder: $e')),
        );
      }
    }
  }

  Future<void> _combineSelected() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFE91E63)),
              const SizedBox(height: 24),
              Text(
                'COMPILING DATA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merging selected units into master log...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pdfFiles = await OfflineDriveService.collectPdfsFromPaths(
        _selectedPaths.toList(),
      );

      if (pdfFiles.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No PDF files found in selection')),
          );
        }
        return;
      }

      final pdfBytes = await OfflineDriveService.generateClubbedPdfFromFiles(
        pdfFiles: pdfFiles,
        onProgress: (c, t) {
          debugPrint('Combining: $c / $t');
        },
      );

      if (mounted && pdfBytes != null) {
        Navigator.pop(context);

        final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        final filename = 'Clubbed_Selected_$timestamp.pdf';

        await Printing.sharePdf(bytes: pdfBytes, filename: filename);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Combined ${pdfFiles.length} PDFs successfully!'),
          ),
        );

        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error combining: $e')));
      }
    }
  }

  void _navigateTo(Directory dir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfflineDriveScreen(initialDirectory: dir),
      ),
    );
  }

  Future<void> _openFile(File file) async {
    final name = file.path.split('/').last;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(file: file, title: name),
      ),
    );
  }

  Future<void> _runBackfill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_alt, color: Color(0xFFFFD700), size: 48),
              const SizedBox(height: 24),
              Text(
                'SYNC REPORTS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update report history? This will scan for missing reports and ensure everything is up to date.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('LATER'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                      ),
                      child: Text('INITIALIZE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isBackfilling = true);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFFFD700)),
                const SizedBox(height: 24),
                Text(
                  'SYNCING REPORTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Updating report data...',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await OfflineDriveService.generateAllBackfill(
        onProgress: (completed, total, status) {
          debugPrint('$status ($completed/$total)');
        },
      );

      if (mounted) {
        Navigator.pop(context);
        _loadContents();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Drive Sync Completed!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error during sync: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBackfilling = false);
      }
    }
  }

  Future<void> _clearOfflineDrive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('CLEAR OFFLINE DRIVE'),
        content: Text('This will delete ALL reports and folders. This action cannot be undone.\n\nAre you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFFF5252)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('CLEAR EVERYTHING')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final root = await OfflineDriveService.getRootDirectory();
      if (await root.exists()) {
        await root.delete(recursive: true);
        await OfflineDriveService.init(); // Re-create root
        await OfflineDriveService.syncStructure(); // Re-sync structure
      }
      if (mounted) {
        _loadContents();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offline Drive Cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing drive: $e')));
      }
    }
  }

  List<FileSystemEntity> get _filteredAndSortedContents {
    List<FileSystemEntity> result = _contents;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((entity) {
        final name = entity.path.split('/').last.toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      int comparison = 0;
      if (_sortBy == 'name') {
        comparison = a.path
            .split('/')
            .last
            .toLowerCase()
            .compareTo(b.path.split('/').last.toLowerCase());
      } else if (_sortBy == 'date') {
        comparison = a.statSync().modified.compareTo(b.statSync().modified);
      } else if (_sortBy == 'type') {
        if (a is Directory && b is File) comparison = -1;
        if (a is File && b is Directory) comparison = 1;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentDir == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
        ),
      );
    }

    final folderName = _currentDir!.path.split('/').last.isEmpty
        ? 'REPORTS'
        : _currentDir!.path.split('/').last.toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: _isSelectionMode
                ? Text(
                    '${_selectedPaths.length} SELECTED',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  )
                : _isSearchMode
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(hintText: 'SCANNING...'),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                  )
                : Text(folderName),
            leading: _isSelectionMode
                ? IconButton(
                    icon: Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                  )
                : _isSearchMode
                ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _isSearchMode = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : (Navigator.canPop(context) ? const BackButton() : null),
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(Icons.select_all),
                      onPressed: _selectAll,
                      tooltip: 'Select All',
                    ),
                    IconButton(
                      icon: Icon(Icons.share_outlined),
                      onPressed: _shareSelected,
                      tooltip: 'Share',
                    ),
                    if (_selectedPaths.length == 1 &&
                        FileSystemEntity.isDirectorySync(_selectedPaths.first))
                      IconButton(
                        icon: Icon(Icons.folder_zip_outlined),
                        onPressed: _zipAndShareSelected,
                        tooltip: 'Zip & Share',
                      ),
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf_outlined),
                      onPressed: _combineSelected,
                      tooltip: 'Combine PDFs',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Color(0xFFFF5252),
                      ),
                      onPressed: _deleteSelected,
                      tooltip: 'Delete',
                    ),
                  ]
                : [
                    if (!_isSearchMode) ...[
                      if (folderName == 'DATA DRIVE' ||
                          folderName == 'OFFLINE DRIVE' ||
                          folderName == 'OFFLINEDRIVE')
                        IconButton(
                          icon: Icon(Icons.sync_outlined),
                          onPressed: _isBackfilling ? null : _runBackfill,
                          tooltip: 'Sync',
                        ),
                      if (folderName == 'OFFLINE DRIVE' || folderName == 'OFFLINEDRIVE')
                        IconButton(
                          icon: Icon(Icons.delete_forever_outlined, color: Color(0xFFFF5252)),
                          onPressed: _clearOfflineDrive,
                          tooltip: 'Clear Drive',
                        ),
                      IconButton(
                        icon: Icon(Icons.search_outlined),
                        onPressed: () => setState(() => _isSearchMode = true),
                        tooltip: 'Search',
                      ),
                      IconButton(
                        icon: Icon(Icons.library_books_outlined),
                        onPressed: _combinePdfs,
                        tooltip: 'Combine All',
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.sort_outlined),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        onSelected: (value) => value == 'toggle_order'
                            ? setState(() => _sortAscending = !_sortAscending)
                            : setState(() => _sortBy = value),
                        itemBuilder: (context) => [
                          _buildSortItem('name', Icons.sort_by_alpha, 'Name'),
                          _buildSortItem(
                            'date',
                            Icons.calendar_today_outlined,
                            'Date',
                          ),
                          _buildSortItem(
                            'type',
                            Icons.category_outlined,
                            'Type',
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem(
                            value: 'toggle_order',
                            child: Row(
                              children: [
                                Icon(
                                  _sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _sortAscending ? 'ASCENDING' : 'DESCENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_contents.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.checklist_outlined),
                          onPressed: () => _enterSelectionMode(''),
                          tooltip: 'Select',
                        ),
                    ],
                  ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: _buildBreadcrumbs(),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
              ),
            )
          else if (_filteredAndSortedContents.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'EMPTY SYSTEM HUB'
                          : 'NO TELEMETRY MATCHES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _filteredAndSortedContents[index];
                  final name = item.path.split('/').last;
                  final isDir = item is Directory;
                  final isSelected = _selectedPaths.contains(item.path);

                  final animation = _staggeredAnimations[index % 20];

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4FC3F7)
                                : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: isDir
                              ? Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C222D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.folder_open_outlined,
                                    color: Color(0xFF4FC3F7),
                                    size: 24,
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C222D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFFE91E63),
                                    size: 24,
                                  ),
                                ),
                          title: Text(
                            name.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: isSelected
                                  ? const Color(0xFF4FC3F7)
                                  : Colors.white70,
                            ),
                          ),
                          subtitle: Text(
                            isDir ? 'FOLDER' : 'REPORT PDF',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white24,
                              letterSpacing: 1,
                            ),
                          ),
                          trailing: isDir && !_isSelectionMode
                              ? Icon(Icons.chevron_right, color: Colors.white10)
                              : _isSelectionMode
                              ? Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.white10,
                                )
                              : null,
                          onLongPress: () => _enterSelectionMode(item.path),
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(item.path);
                            } else {
                              if (isDir) {
                                _navigateTo(item);
                              } else {
                                _openFile(item as File);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }, childCount: _filteredAndSortedContents.length),
              ),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
    String value,
    IconData icon,
    String label,
  ) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF4FC3F7) : Colors.white24,
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF4FC3F7) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _combinePdfs() async {
    final currentDir = _currentDir;
    if (currentDir == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                color: Color(0xFF4FC3F7),
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                'COMBINE ALL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Combine all PDFs in this hub and its sub-sectors into a single master log?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('ABORT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('PROCEED'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF4FC3F7)),
              const SizedBox(height: 24),
              Text(
                'COMPILING HUB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scanning and merging all sub-sector telemetry...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pdfBytes = await OfflineDriveService.generateClubbedPdfFromFolder(
        folder: currentDir,
        onProgress: (c, t) {
          debugPrint('Progress: $c / $t');
        },
      );

      if (mounted && pdfBytes != null) {
        Navigator.pop(context);

        final folderName = currentDir.path.split('/').last;
        final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        final filename = 'Clubbed_${_sanitizeName(folderName)}_$timestamp.pdf';

        await Printing.sharePdf(bytes: pdfBytes, filename: filename);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDFs combined successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _sanitizeName(String input) {
    return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  Widget _buildBreadcrumbs() {
    return FutureBuilder<Directory>(
      future: OfflineDriveService.getRootDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final rootPath = snapshot.data!.path;
        final relativePath = _currentDir!.path.replaceFirst(rootPath, '');
        final parts = relativePath
            .split('/')
            .where((p) => p.isNotEmpty)
            .toList();

        return Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBreadcrumbItem('DRIVE', () async {
                final rootDir = await OfflineDriveService.getRootDirectory();
                if (_currentDir?.path != rootDir.path) {
                  _navigateTo(rootDir);
                }
              }),
              ...parts.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_right, size: 14, color: Colors.white10),
                    _buildBreadcrumbItem(name.toUpperCase(), () {
                      // Construct path to this point
                      String path = rootPath;
                      for (int i = 0; i <= index; i++) {
                        path += '/${parts[i]}';
                      }
                      _navigateTo(Directory(path));
                    }),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbItem(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4FC3F7),
          letterSpacing: 1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entranceController.dispose();
    super.dispose();
  }
}
