import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/word_pdf_service.dart';
import 'inspection_form_screen.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final inspections = DatabaseService.getAllInspections();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        value: 'pdf_simple',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Share PDF (Simple)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'word_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Share PDF (Word Template)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'word',
                        child: Row(
                          children: [
                            Icon(Icons.article, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Export Word Document'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      try {
                        if (value == 'pdf_simple') {
                          await PdfService.shareInspection(inspection);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF shared successfully')),
                            );
                          }
                        } else if (value == 'word_pdf') {
                          // Show loading indicator
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
                                    Text('Generating PDF from Word template...'),
                                  ],
                                ),
                                duration: Duration(seconds: 10),
                              ),
                            );
                          }
                          await WordPdfService.shareInspection(inspection);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF shared successfully')),
                            );
                          }
                        } else if (value == 'word') {
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
