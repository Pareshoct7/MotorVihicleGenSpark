import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../services/offline_drive_service.dart';

class OfflineDriveScreen extends StatefulWidget {
  final Directory? initialDirectory;

  const OfflineDriveScreen({super.key, this.initialDirectory});

  @override
  State<OfflineDriveScreen> createState() => _OfflineDriveScreenState();
}

class _OfflineDriveScreenState extends State<OfflineDriveScreen> {
  Directory? _currentDir;
  List<FileSystemEntity> _contents = [];
  bool _isLoading = true;
  bool _isBackfilling = false;
  
  // Selection state
  bool _isSelectionMode = false;
  Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
  }

  Future<void> _initializeDirectory() async {
    final rootDir = widget.initialDirectory ?? await OfflineDriveService.getRootDirectory();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading folder: $e')),
        );
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selectedPaths.length} item(s)?\\n\\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  Future<void> _shareSelected() async {
    try {
      final pdfPaths = _selectedPaths.where((p) => p.toLowerCase().endsWith('.pdf')).toList();
      
      if (pdfPaths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF files selected')),
        );
        return;
      }

      final xFiles = pdfPaths.map((p) => XFile(p)).toList();
      await Share.shareXFiles(xFiles, text: 'Inspection Reports');
      
      _exitSelectionMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _combineSelected() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Combining PDFs...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing selected files...'),
          ],
        ),
      ),
    );

    try {
      final pdfFiles = await OfflineDriveService.collectPdfsFromPaths(_selectedPaths.toList());
      
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
          SnackBar(content: Text('Combined ${pdfFiles.length} PDFs successfully!')),
        );
        
        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error combining: $e')),
        );
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
    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'Inspection Report');
  }

  Future<void> _runBackfill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync & Backfill Drive'),
        content: const Text(
          'This will scan for missing reports (last 1 year) and generate them automatically if they don\'t exist.\\n\\nThis may take a minute.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBackfilling = true);

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Syncing...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                   LinearProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Processing vehicle history...'),
                ],
              ),
            );
          }
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
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Drive Sync Completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during sync: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackfilling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentDir == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Drive')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final folderName = _currentDir!.path.split('/').last.isEmpty 
        ? 'Offline Drive' 
        : _currentDir!.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedPaths.length} selected' : folderName),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareSelected,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _combineSelected,
                  tooltip: 'Combine PDFs',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                  tooltip: 'Delete',
                ),
              ]
            : [
                if (folderName == 'Offline Drive' || folderName == 'OfflineDrive')
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _isBackfilling ? null : _runBackfill,
                    tooltip: 'Sync & Backfill',
                  ),
                if (_contents.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: () => _enterSelectionMode(''),
                    tooltip: 'Select',
                  ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contents.isEmpty
              ? const Center(child: Text('Empty Folder'))
              : ListView.builder(
                  itemCount: _contents.length,
                  itemBuilder: (context, index) {
                    final item = _contents[index];
                    final name = item.path.split('/').last;
                    final isDir = item is Directory;
                    final isSelected = _selectedPaths.contains(item.path);

                    return ListTile(
                      leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(item.path),
                            )
                          : Icon(
                              isDir ? Icons.folder : Icons.picture_as_pdf,
                              color: isDir ? Colors.amber : Colors.red,
                              size: 32,
                            ),
                      title: Text(name),
                      trailing: isDir && !_isSelectionMode ? const Icon(Icons.chevron_right) : null,
                      selected: isSelected,
                      onLongPress: () => _enterSelectionMode(item.path),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(item.path);
                        } else {
                          if (isDir) {
                            _navigateTo(item as Directory);
                          } else {
                            _openFile(item as File);
                          }
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: !_isSelectionMode && !_isLoading && _contents.isNotEmpty && _currentDir != null
          ? FloatingActionButton.extended(
              onPressed: _combinePdfs,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Combine All'),
              tooltip: 'Combine all PDFs in this folder',
            )
          : null,
    );
  }

  Future<void> _combinePdfs() async {
    final currentDir = _currentDir;
    if (currentDir == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Combine All PDFs'),
        content: const Text(
          'This will combine all PDFs in this folder and its subfolders into a single PDF.\\n\\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Combine'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Combining PDFs...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing PDFs...'),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _sanitizeName(String input) {
    return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
