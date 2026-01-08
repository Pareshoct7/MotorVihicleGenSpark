import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'inspection_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  String? _selectedVehicleId;
  String? _selectedStoreId;
  String? _selectedDriverId;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Inspection> _filteredInspections = [];
  bool _isGeneratingBulkPdf = false;
  
  // Selection State
  final Set<String> _selectedReportIds = {};
  bool _explicitSelectionMode = false;
  
  bool get _isSelectionMode => _explicitSelectionMode || _selectedReportIds.isNotEmpty;

  late AnimationController _entranceController;
  final List<Animation<double>> _staggeredAnimations = [];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 10; i++) {
      _staggeredAnimations.add(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(i * 0.1, 0.6 + (i * 0.04), curve: Curves.easeOutCubic),
        ),
      );
    }
    _applyFilters();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var inspections = DatabaseService.getAllInspections();

    // Filter by vehicle
    if (_selectedVehicleId != null) {
      inspections = inspections
          .where((i) => i.vehicleId == _selectedVehicleId)
          .toList();
    }

    // Filter by store
    if (_selectedStoreId != null) {
      inspections =
          inspections.where((i) => i.storeId == _selectedStoreId).toList();
    }

    // Filter by driver
    if (_selectedDriverId != null) {
      inspections =
          inspections.where((i) => i.driverId == _selectedDriverId).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      inspections = inspections
          .where((i) =>
              i.inspectionDate.isAfter(_startDate!) ||
              i.inspectionDate.isAtSameMomentAs(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      inspections = inspections
          .where((i) =>
              i.inspectionDate.isBefore(endOfDay) ||
              i.inspectionDate.isAtSameMomentAs(endOfDay))
          .toList();
    }

    setState(() {
      _filteredInspections = inspections;
      _selectedReportIds.clear(); 
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedVehicleId = null;
      _selectedStoreId = null;
      _selectedDriverId = null;
      _startDate = null;
      _endDate = null;
      _selectedReportIds.clear();
      _explicitSelectionMode = false;
    });
    _applyFilters();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedReportIds.contains(id)) {
        _selectedReportIds.remove(id);
      } else {
        _selectedReportIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedReportIds.length == _filteredInspections.length) {
        _selectedReportIds.clear();
      } else {
        _selectedReportIds.addAll(_filteredInspections.map((i) => i.id));
      }
    });
  }
  
  void _clearSelection() {
    setState(() {
      _selectedReportIds.clear();
      _explicitSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedReports() async {
    if (_selectedReportIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reports'),
        content: Text(
          'Are you sure you want to delete ${_selectedReportIds.length} reports? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete locally
    for (final id in _selectedReportIds) {
      await DatabaseService.deleteInspection(id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports deleted')),
      );
      _clearSelection();
      _applyFilters(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (_isSelectionMode)
            SliverAppBar.medium(
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedReportIds.length} SELECTED'),
              backgroundColor: const Color(0xFF161B22),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedReportIds.length == _filteredInspections.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                  onPressed: _deleteSelectedReports,
                ),
                const SizedBox(width: 8),
              ],
            )
          else
            SliverAppBar.large(
            automaticallyImplyLeading: true,
            leading: Navigator.canPop(context) ? const BackButton() : null,
            expandedHeight: 140,
              floating: false,
              pinned: true,
              title: const Text('INSPECTIONS'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.checklist, size: 28),
                  onPressed: () => setState(() => _explicitSelectionMode = true),
                ),
                if (_filteredInspections.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 28),
                    onPressed: _generateBulkPdfs,
                  ),
                const SizedBox(width: 8),
              ],
            ),
          
          SliverToBoxAdapter(
            child: ExpansionTile(
              title: Row(
                children: [
                   const Icon(Icons.tune, size: 18, color: Color(0xFF4FC3F7)),
                   const SizedBox(width: 12),
                   const Text(
                    'FILTERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF4FC3F7),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedVehicleId != null || _selectedStoreId != null || _selectedDriverId != null || _startDate != null || _endDate != null)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4FC3F7),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              backgroundColor: const Color(0xFF0D1117),
              collapsedBackgroundColor: const Color(0xFF0D1117),
              iconColor: const Color(0xFF4FC3F7),
              collapsedIconColor: Colors.white24,
              children: [
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(labelText: 'VEHICLE', prefixIcon: Icon(Icons.directions_car_outlined)),
                  dropdownColor: const Color(0xFF161B22),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ALL VEHICLES')),
                    ...vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.registrationNo))),
                  ],
                  onChanged: (val) { setState(() => _selectedVehicleId = val); _applyFilters(); },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStoreId,
                  decoration: const InputDecoration(labelText: 'STORE HUB', prefixIcon: Icon(Icons.store_outlined)),
                  dropdownColor: const Color(0xFF161B22),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ALL HUBS')),
                    ...stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.toUpperCase()))),
                  ],
                  onChanged: (val) { setState(() => _selectedStoreId = val); _applyFilters(); },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) { setState(() => _startDate = date); _applyFilters(); }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'FROM'),
                          child: Text(_startDate != null ? dateFormat.format(_startDate!).toUpperCase() : 'ANYTIME'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) { setState(() => _endDate = date); _applyFilters(); }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'TO'),
                          child: Text(_endDate != null ? dateFormat.format(_endDate!).toUpperCase() : 'ANYTIME'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('RESET FILTERS'),
                  style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),

          _filteredInspections.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.analytics_outlined, size: 80, color: Colors.white10),
                        const SizedBox(height: 24),
                        const Text(
                          'NO TELEMETRY DATA FOUND',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _clearFilters, child: const Text('RESET FILTERS')),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final inspection = _filteredInspections[index];
                        final animation = _staggeredAnimations[math.min(index, 9)];
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: animation.drive(Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)),
                            child: _buildInspectionCard(context, inspection),
                          ),
                        );
                      },
                      childCount: _filteredInspections.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  Widget _buildInspectionCard(BuildContext context, Inspection inspection) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isSelected = _selectedReportIds.contains(inspection.id);
    const accentColor = Color(0xFF4FC3F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? accentColor : accentColor.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onLongPress: () => _toggleSelection(inspection.id),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(inspection.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionFormScreen(
                  inspection: inspection,
                  isViewOnly: true,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => _toggleSelection(inspection.id),
                  activeColor: accentColor,
                ),
                const SizedBox(width: 8),
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${inspection.completionPercentage.toInt()}%',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspection.vehicleRegistrationNo.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(inspection.inspectionDate).toUpperCase()} • ${inspection.employeeName.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      inspection.storeName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white30),
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 12),
                          Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18),
                          SizedBox(width: 12),
                          Text('EXPORT PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InspectionFormScreen(
                            inspection: inspection,
                            isViewOnly: true,
                          ),
                        ),
                      );
                    } else if (value == 'pdf') {
                      await PdfService.shareTemplateMatchingInspection(inspection);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateBulkPdfs() async {
    if (_filteredInspections.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Bulk PDFs'),
        content: Text(
          'Generate PDFs for all ${_filteredInspections.length} filtered reports?\n\nThis may take a few moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isGeneratingBulkPdf = true;
    });

    // Show progress dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Generating PDFs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing ${_filteredInspections.length} reports...'),
          ],
        ),
      ),
    );

    try {
      for (final inspection in _filteredInspections) {
        await PdfService.shareTemplateMatchingInspection(inspection);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_filteredInspections.length} PDFs generated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDFs: $e')),
        );
      }
    } finally {
      setState(() {
        _isGeneratingBulkPdf = false;
      });
    }
  }
}
