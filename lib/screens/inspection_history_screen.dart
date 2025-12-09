import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/word_pdf_service.dart';
import 'package:printing/printing.dart';
import 'inspection_form_screen.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedInspectionIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedInspectionIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedInspectionIds.contains(id)) {
        _selectedInspectionIds.remove(id);
        if (_selectedInspectionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedInspectionIds.add(id);
      }
    });
  }

  Future<void> _shareSelectedInspections() async {
    if (_selectedInspectionIds.isEmpty) return;

    final allInspections = DatabaseService.getAllInspections();
    final selectedInspections = allInspections
        .where((i) => _selectedInspectionIds.contains(i.id))
        .toList();

    if (selectedInspections.isEmpty) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Generating clubbed PDF report...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      final pdfData = await PdfService.generateClubbedInspectionPdf(selectedInspections);
      
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'inspections_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report shared successfully')),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedInspectionIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspections = DatabaseService.getAllInspections();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedInspectionIds.length} Selected' 
            : 'Inspection History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedInspections,
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple',
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: inspections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No inspections yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return _buildInspectionCard(context, inspection);
              },
            ),
    );
  }

  Widget _buildInspectionCard(BuildContext context, Inspection inspection) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isSelected = _selectedInspectionIds.contains(inspection.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: InkWell(
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
            ).then((_) => setState(() {}));
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedInspectionIds.add(inspection.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleSelection(inspection.id),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inspection.vehicleRegistrationNo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(inspection.inspectionDate),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: inspection.completionPercentage / 100,
                                backgroundColor: Colors.grey.shade300,
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${inspection.completionPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          inspection.storeName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            inspection.employeeName,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${inspection.odometerReading} km',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (!_isSelectionMode) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InspectionFormScreen(
                                    inspection: inspection,
                                    isViewOnly: true,
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View'),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.share),
                            tooltip: 'Share Options',
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'pdf_template',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: Colors.green),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Share PDF (Template Match)'),
                                        Text(
                                          'Exact template layout • Works offline',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'pdf_simple',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Share PDF (Basic)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'word',
                                child: Row(
                                  children: [
                                    Icon(Icons.article, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Export Word Document'),
                                        Text(
                                          'Desktop only (Python required)',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              try {
                                if (value == 'pdf_template') {
                                  // Template-matching PDF - Works offline on all platforms
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 16),
                                            Text('Generating template-matching PDF...'),
                                          ],
                                        ),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                  await PdfService.shareTemplateMatchingInspection(inspection);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('PDF shared successfully')),
                                    );
                                  }
                                } else if (value == 'pdf_simple') {
                                  await PdfService.shareTemplateMatchingInspection(inspection);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('PDF shared successfully')),
                                    );
                                  }
                                } else if (value == 'word') {
                                  // Word document generation (desktop only with Python)
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 16),
                                            Text('Generating Word document...'),
                                          ],
                                        ),
                                        duration: Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                  final wordPath = await WordPdfService.generateWordDocument(inspection);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Word document saved: $wordPath')),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'repeat',
                                child: Row(
                                  children: [
                                    Icon(Icons.repeat, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Repeat Inspection'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'repeat') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InspectionFormScreen(
                                      baseInspection: inspection,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              } else if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InspectionFormScreen(
                                      inspection: inspection,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              } else if (value == 'delete') {
                                _deleteInspection(context, inspection);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteInspection(BuildContext context, Inspection inspection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspection'),
        content: Text(
          'Are you sure you want to delete this inspection for ${inspection.vehicleRegistrationNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteInspection(inspection.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inspection deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
