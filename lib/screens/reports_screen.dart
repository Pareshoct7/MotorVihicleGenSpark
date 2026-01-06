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

class _ReportsScreenState extends State<ReportsScreen> {
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

  @override
  void initState() {
    super.initState();
    _applyFilters();
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
      // Clear selection if items are filtered out, or keep? 
      // safer to clear to avoid deleting unseen items
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedReportIds.length} Selected'),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedReportIds.length == _filteredInspections.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: _selectAll,
                  tooltip: _selectedReportIds.length < _filteredInspections.length
                      ? 'Select All'
                      : 'Deselect All',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedReports,
                  tooltip: 'Delete Selected',
                ),
              ],
            )
          : AppBar(
              title: const Text('Inspection Reports'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                /// Edit/Select Button
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () {
                    setState(() {
                      _explicitSelectionMode = true;
                    });
                  },
                  tooltip: 'Select Reports',
                ),
                if (_filteredInspections.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: _generateBulkPdfs,
                    tooltip: 'Generate All PDFs',
                  ),
              ],
            ),
      body: Column(
        children: [
          // Filter Section (Hide in selection mode or keep? Keeping for context)
          if (!_isSelectionMode)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Filter
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Vehicles'),
                      ),
                      ...vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(vehicle.registrationNo),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleId = value;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Store Filter
                  DropdownButtonFormField<String>(
                    value: _selectedStoreId,
                    decoration: const InputDecoration(
                      labelText: 'Store',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Stores'),
                      ),
                      ...stores.map((store) {
                        return DropdownMenuItem(
                          value: store.id,
                          child: Text(store.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStoreId = value;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Driver Filter
                  DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    decoration: const InputDecoration(
                      labelText: 'Driver/Employee',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Drivers'),
                      ),
                      ...drivers.map((driver) {
                        return DropdownMenuItem(
                          value: driver.id,
                          child: Text(driver.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDriverId = value;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date Range
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
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                              _applyFilters();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : 'All',
                              style: TextStyle(
                                color: _startDate != null
                                    ? null
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                              _applyFilters();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : 'All',
                              style: TextStyle(
                                color: _endDate != null
                                    ? null
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Results Count
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredInspections.length} Reports Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results List
          Expanded(
            child: _filteredInspections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredInspections.length,
                    itemBuilder: (context, index) {
                      final inspection = _filteredInspections[index];
                      return _buildInspectionCard(context, inspection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(BuildContext context, Inspection inspection) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isSelected = _selectedReportIds.contains(inspection.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onLongPress: () => _toggleSelection(inspection.id),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(inspection.id);
          } else {
             // Normal View Action
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
        child: ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (val) => _toggleSelection(inspection.id),
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${inspection.completionPercentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          title: Text(
            inspection.vehicleRegistrationNo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateFormat.format(inspection.inspectionDate)),
              Text('${inspection.storeName} • ${inspection.employeeName}'),
            ],
          ),
          trailing: _isSelectionMode
              ? null
              : PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text('Generate PDF'),
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
                      await PdfService.shareTemplateMatchingInspection(
                          inspection);
                    }
                  },
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
