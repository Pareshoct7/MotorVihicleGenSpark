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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Motor Vehicle Inspection Form',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // 1. Inspection Details
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '1. Inspection Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Vehicle Registration No:'),
                        pw.Text(
                          inspection.vehicleRegistrationNo,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Store:'),
                        pw.Text(
                          inspection.storeName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Odometer Reading:'),
                        pw.Text(
                          inspection.odometerReading,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:'),
                        pw.Text(
                          dateFormat.format(inspection.inspectionDate),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Employee Name:'),
                    pw.Text(
                      inspection.employeeName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // 2. Inspection Checklist
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '2. Inspection Checklist',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Create table with checklist items
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column - Tyres, Outside, Mechanical
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildChecklistSection(
                            'Tyres',
                            [
                              _CheckItem('Tyres (tread depth)', inspection.tyresTreadDepth),
                              _CheckItem('Wheel nuts', inspection.wheelNuts),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          _buildChecklistSection(
                            'Outside',
                            [
                              _CheckItem('Cleanliness', inspection.cleanliness),
                              _CheckItem('Body damage: scratches/dents etc.', inspection.bodyDamage),
                              _CheckItem('Mirrors & Windows', inspection.mirrorsWindows),
                              _CheckItem('Signage (if applicable)', inspection.signage),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          _buildChecklistSection(
                            'Mechanical',
                            [
                              _CheckItem('Engine – oil & water', inspection.engineOilWater),
                              _CheckItem('Brakes', inspection.brakes),
                              _CheckItem('Transmission', inspection.transmission),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // Right column - Electrical, Cab
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildChecklistSection(
                            'Electrical',
                            [
                              _CheckItem('Both tail lights', inspection.tailLights),
                              _CheckItem('Headlights (low beam)', inspection.headlightsLowBeam),
                              _CheckItem('Headlights (high beam)', inspection.headlightsHighBeam),
                              _CheckItem('Reverse lights', inspection.reverseLights),
                              _CheckItem('Brake lights', inspection.brakeLights),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          _buildChecklistSection(
                            'Cab',
                            [
                              _CheckItem('Windscreen & wipers', inspection.windscreenWipers),
                              _CheckItem('Horn', inspection.horn),
                              _CheckItem('Indicators', inspection.indicators),
                              _CheckItem('Seat belts', inspection.seatBelts),
                              _CheckItem('Cleanliness', inspection.cabCleanliness),
                              _CheckItem('Service log book available', inspection.serviceLogBook),
                              _CheckItem('Spare keys available in store', inspection.spareKeys),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (inspection.bodyDamageNotes != null &&
                    inspection.bodyDamageNotes!.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Body Damage Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(inspection.bodyDamageNotes!),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // 3. Corrective Actions
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '3. Corrective Actions/notes/issues',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  height: 80,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  padding: const pw.EdgeInsets.all(5),
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
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '4. Sign-off',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'I hereby declare that the above information is true and correct at the time of inspection.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Signature:'),
                        pw.Container(
                          width: 200,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black),
                            ),
                          ),
                          child: inspection.signature != null
                              ? pw.Text(
                                  inspection.signature!,
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                )
                              : pw.Container(),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:'),
                        pw.Text(
                          dateFormat.format(inspection.inspectionDate),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildChecklistSection(
    String title,
    List<_CheckItem> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: item.checked == true
                        ? pw.Center(
                            child: pw.Text(
                              '✓',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Text(
                      item.label,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            )),
      ],
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
