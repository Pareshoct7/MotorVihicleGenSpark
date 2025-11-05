import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';

class PdfService {
  static Future<Uint8List> generateInspectionPdf(Inspection inspection) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'Motor Vehicle Inspection Form',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // 1. Inspection Details
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '1. Inspection Details',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    
                    // Row 1: Vehicle Reg and Store
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildDetailField('Vehicle Registration No:', inspection.vehicleRegistrationNo),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildDetailField('Store:', inspection.storeName),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    
                    // Row 2: Odometer and Date
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildDetailField('Odometer Reading:', inspection.odometerReading),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildDetailField('Date:', dateFormat.format(inspection.inspectionDate)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    
                    // Row 3: Employee Name
                    _buildDetailField('Employee Name:', inspection.employeeName),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // 2. Inspection Checklist
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '2. Inspection Checklist',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    
                    // Two-column layout
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Tyres section
                              _buildChecklistCategory('Tyres', [
                                _CheckItem('Tyres (tread depth)', inspection.tyresTreadDepth),
                                _CheckItem('Wheel nuts', inspection.wheelNuts),
                              ]),
                              pw.SizedBox(height: 12),
                              
                              // Outside section
                              _buildChecklistCategory('Outside', [
                                _CheckItem('Cleanliness', inspection.cleanliness),
                                _CheckItem('Body damage: scratches/dents etc.\n(circle on diagram below)', inspection.bodyDamage),
                                _CheckItem('Mirrors & Windows', inspection.mirrorsWindows),
                                _CheckItem('Signage (if applicable)', inspection.signage),
                              ]),
                              pw.SizedBox(height: 12),
                              
                              // Mechanical section
                              _buildChecklistCategory('Mechanical', [
                                _CheckItem('Engine – oil & water', inspection.engineOilWater),
                                _CheckItem('Brakes', inspection.brakes),
                                _CheckItem('Transmission', inspection.transmission),
                              ]),
                            ],
                          ),
                        ),
                        
                        pw.SizedBox(width: 30),
                        
                        // Right Column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Electrical section
                              _buildChecklistCategory('Electrical', [
                                _CheckItem('Both tail lights', inspection.tailLights),
                                _CheckItem('Headlights (low beam)', inspection.headlightsLowBeam),
                                _CheckItem('Headlights (high beam)', inspection.headlightsHighBeam),
                                _CheckItem('Reverse lights', inspection.reverseLights),
                                _CheckItem('Brake lights', inspection.brakeLights),
                              ]),
                              pw.SizedBox(height: 12),
                              
                              // Cab section
                              _buildChecklistCategory('Cab', [
                                _CheckItem('Windscreen & wipers', inspection.windscreenWipers),
                                _CheckItem('Horn', inspection.horn),
                                _CheckItem('Indicators', inspection.indicators),
                                _CheckItem('Seat belts', inspection.seatBelts),
                                _CheckItem('Cleanliness', inspection.cabCleanliness),
                                _CheckItem('Service log book available', inspection.serviceLogBook),
                                _CheckItem('Spare keys available in store', inspection.spareKeys),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Vehicle damage diagram placeholder
                    pw.SizedBox(height: 15),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Circle any areas with existing damage.',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          // Simple vehicle outline representation
                          pw.Container(
                            width: 200,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.black),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'Vehicle Diagram',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ),
                          ),
                          if (inspection.bodyDamageNotes != null && inspection.bodyDamageNotes!.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Body Damage Notes: ${inspection.bodyDamageNotes}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // 3. Corrective Actions
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '3. Corrective Actions/notes/issues',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      height: 60,
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        inspection.correctiveActions ?? '',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // 4. Sign-off
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '4. Sign-off',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'I hereby declare that the above information is true and correct at the time of inspection.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Signature:', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              width: 180,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.black),
                                ),
                              ),
                              padding: const pw.EdgeInsets.only(bottom: 5),
                              child: inspection.signature != null
                                  ? pw.Text(
                                      inspection.signature!,
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    )
                                  : pw.Container(height: 20),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              dateFormat.format(inspection.inspectionDate),
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper method to build detail fields
  static pw.Widget _buildDetailField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper method to build checklist category
  static pw.Widget _buildChecklistCategory(
    String title,
    List<_CheckItem> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.Text(
              'OK?',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        ...items.map((item) => _buildChecklistItem(item)),
      ],
    );
  }

  // Helper method to build individual checklist item
  static pw.Widget _buildChecklistItem(_CheckItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Checkbox
          pw.Container(
            width: 14,
            height: 14,
            margin: const pw.EdgeInsets.only(top: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: item.checked == true
                ? pw.Center(
                    child: pw.Text(
                      '✓',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 6),
          // Label
          pw.Expanded(
            child: pw.Text(
              item.label,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printInspection(Inspection inspection) async {
    final pdfData = await generateInspectionPdf(inspection);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
    );
  }

  static Future<void> shareInspection(Inspection inspection) async {
    final pdfData = await generateInspectionPdf(inspection);
    await Printing.sharePdf(
      bytes: pdfData,
      filename:
          'inspection_${inspection.vehicleRegistrationNo}_${DateFormat('yyyyMMdd').format(inspection.inspectionDate)}.pdf',
    );
  }
}

class _CheckItem {
  final String label;
  final bool? checked;

  _CheckItem(this.label, this.checked);
}
