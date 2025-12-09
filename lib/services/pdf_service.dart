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

  /// Generate PDF that exactly matches the Word template layout
  /// Works offline on all platforms (Android, iOS, Desktop)
  static Future<Uint8List> generateTemplateMatchingPdf(Inspection inspection) async {
    final pdf = pw.Document();

    // Load images
    final logoImage = await imageFromAssetBundle('assets/dominos_logo.png');
    final diagramImage = await imageFromAssetBundle('assets/vehicle_diagram.jpeg');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20), // Reduced margin to 20
        build: (context) => _buildTemplateMatchingPage(inspection, logoImage, diagramImage),
      ),
    );

    return pdf.save();
  }

  /// Generate a single PDF containing multiple inspections (Clubbed Report)
  static Future<Uint8List> generateClubbedInspectionPdf(List<Inspection> inspections) async {
    final pdf = pw.Document();

    // Load images once
    final logoImage = await imageFromAssetBundle('assets/dominos_logo.png');
    final diagramImage = await imageFromAssetBundle('assets/vehicle_diagram.jpeg');

    for (final inspection in inspections) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildTemplateMatchingPage(inspection, logoImage, diagramImage),
        ),
      );
    }

    return pdf.save();
  }

  /// Build the list of widgets for a single inspection page
  static List<pw.Widget> _buildTemplateMatchingPage(
    Inspection inspection,
    pw.ImageProvider logoImage,
    pw.ImageProvider diagramImage,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return [
      // Header with Logo
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              color: PdfColors.blue900,
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: pw.Text(
                'Motor Vehicle Inspection Form',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Image(logoImage, width: 60),
        ],
      ),
      pw.SizedBox(height: 10),

      // 1. Inspection Details
      pw.Text(
        '1. Inspection Details',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      _buildDetailsTable(inspection, dateFormat),
      
      pw.SizedBox(height: 10),

      // 2. Inspection Checklist
      pw.Text(
        '2. Inspection Checklist',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      _buildChecklistTable(inspection),
      
      pw.SizedBox(height: 8),

      // Part 3: Vehicle Diagram and Spare Keys
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Circle any areas with existing damage.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Image(diagramImage, height: 150, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildCheckbox(inspection.spareKeys),
              pw.SizedBox(width: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Text(
                  'Spare keys available in store',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
      
      pw.SizedBox(height: 8),

      // 3. Corrective Actions
      pw.Text(
        '3. Corrective Actions/notes/issues',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Stack(
          children: [
            pw.Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: pw.Text(
                inspection.correctiveActions ?? '',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 1,
                color: PdfColors.black,
              ),
            ),
            pw.Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 1,
                color: PdfColors.black,
              ),
            ),
            pw.Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 1,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 8),

      // 4. Sign-off
      pw.Text(
        '4. Sign-off',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'I hereby declare that the above information is true and correct at the time of inspection.',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Employee Signature Section
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Employee Signature', style: const pw.TextStyle(fontSize: 10)),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  children: [
                    // Signature box
                    pw.TableRow(
                      children: [
                        pw.Container(
                          height: 40,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              inspection.signature ?? '',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Date box
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Date    ${dateFormat.format(inspection.inspectionDate)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          // Manager Signature Section
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Manager Signature', style: const pw.TextStyle(fontSize: 10)),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  children: [
                    // Signature box
                    pw.TableRow(
                      children: [
                        pw.Container(
                          height: 40,
                        ),
                      ],
                    ),
                    // Date box
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Date',
                            style: const pw.TextStyle(fontSize: 10),
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
      ),
    ];
  }

  /// Build inspection details table matching Word template Table 0
  static pw.Widget _buildDetailsTable(Inspection inspection, DateFormat dateFormat) {
    return pw.Column(
      children: [
        // Row 1: Vehicle Reg & Store
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('Vehicle Registration No:', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.Expanded(
              child: _buildValueBox(inspection.vehicleRegistrationNo, bottomBorder: false),
            ),
            pw.SizedBox(width: 10),
            pw.SizedBox(
              width: 40,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('Store:', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.Expanded(
              child: _buildValueBox(inspection.storeName, bottomBorder: false),
            ),
          ],
        ),
        // Row 2: Odometer & Date (Connected to Row 1)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('Odometer Reading:', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.Expanded(
              child: _buildValueBox(inspection.odometerReading, bottomBorder: false),
            ),
            pw.SizedBox(width: 10),
            pw.SizedBox(
              width: 40,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('Date:', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.Expanded(
              child: _buildValueBox(dateFormat.format(inspection.inspectionDate), bottomBorder: false),
            ),
          ],
        ),
        // Row 3: Employee Name (Connected to Row 2)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('Employee Name', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.Expanded(
              child: _buildValueBox(inspection.employeeName),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build a bordered value box
  static pw.Widget _buildValueBox(String value, {bool bottomBorder = true}) {
    return pw.Container(
      height: 20, // Fixed height for consistency
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: const pw.BorderSide(color: PdfColors.black, width: 0.5),
          left: const pw.BorderSide(color: PdfColors.black, width: 0.5),
          right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
          bottom: bottomBorder 
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        value,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  /// Build checklist table matching Word template Part 2
  static pw.Widget _buildChecklistTable(Inspection inspection) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column
        pw.Expanded(
          child: pw.Column(
            children: [
              _buildChecklistSection(
                'Tyres',
                [
                  _ChecklistItem('Tyres (tread depth)', inspection.tyresTreadDepth),
                  _ChecklistItem('Wheel nuts', inspection.wheelNuts),
                ],
                showOk: true,
              ),
              pw.SizedBox(height: 8),
              _buildChecklistSection(
                'Outside',
                [
                  _ChecklistItem('Cleanliness', inspection.cleanliness),
                  _ChecklistItem('Body damage: scratches/dents\netc. (circle on diagram below)', inspection.bodyDamage),
                  _ChecklistItem('Mirrors & Windows', inspection.mirrorsWindows),
                  _ChecklistItem('Signage (if applicable)', inspection.signage),
                ],
              ),
              pw.SizedBox(height: 8),
              _buildChecklistSection(
                'Mechanical',
                [
                  _ChecklistItem('Engine - oil & water', inspection.engineOilWater),
                  _ChecklistItem('Brakes', inspection.brakes),
                  _ChecklistItem('Transmission', inspection.transmission),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 15),
        // Right Column
        pw.Expanded(
          child: pw.Column(
            children: [
              _buildChecklistSection(
                'Electrical',
                [
                  _ChecklistItem('Both tail lights', inspection.tailLights),
                  _ChecklistItem('Headlights (low beam)', inspection.headlightsLowBeam),
                  _ChecklistItem('Headlights (high beam)', inspection.headlightsHighBeam),
                  _ChecklistItem('Reverse lights', inspection.reverseLights),
                  _ChecklistItem('Brake lights', inspection.brakeLights),
                ],
                showOk: true,
              ),
              pw.SizedBox(height: 8),
              _buildChecklistSection(
                'Cab',
                [
                  _ChecklistItem('Windscreen & wipers', inspection.windscreenWipers),
                  _ChecklistItem('Horn', inspection.horn),
                  _ChecklistItem('Indicators', inspection.indicators),
                  _ChecklistItem('Seat belts', inspection.seatBelts),
                  _ChecklistItem('Cleanliness', inspection.cabCleanliness),
                  _ChecklistItem('Service log book available', inspection.serviceLogBook),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildChecklistSection(
    String title,
    List<_ChecklistItem> items, {
    bool showOk = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header Row
        pw.Row(
          children: [
            pw.SizedBox(
              width: 25,
              child: showOk
                  ? pw.Text('OK?', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))
                  : null,
            ),
            pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 2),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isFirst = index == 0;
          
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Align top for multi-line text
            children: [
              // Checkbox
              pw.Container(
                width: 25,
                alignment: pw.Alignment.topLeft,
                padding: const pw.EdgeInsets.only(top: 2), // Align with text box
                child: _buildCheckbox(item.value),
              ),
              // Text Box
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      top: isFirst ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
                      left: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                      right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                      bottom: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: pw.Text(item.text, style: const pw.TextStyle(fontSize: 9)),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildCheckbox(bool? value) {
    return pw.Container(
      width: 10,
      height: 10,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: value == true
          ? pw.Center(
              child: pw.SvgImage(
                svg: '<svg viewBox="0 0 10 10"><path d="M 2 5 L 4 8 L 8 2" stroke="black" stroke-width="1.5" fill="none"/></svg>',
                width: 8,
                height: 8,
              ),
            )
          : null,
    );
  }

  /// Build spare keys table matching Word template Table 2
  static pw.Widget _buildSpareKeysTable(Inspection inspection) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            _buildCheckboxCell(inspection.spareKeys),
            _buildTableCell('Spare keys available in store', fontSize: 9),
          ],
        ),
      ],
    );
  }

  /// Build signatures table matching Word template Table 3
  static pw.Widget _buildSignaturesTable(Inspection inspection, DateFormat dateFormat) {
    final formattedDate = dateFormat.format(inspection.inspectionDate);
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FixedColumnWidth(20),  // Middle separator column
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          children: [
            _buildTableCell('Employee Signature', bold: true, fontSize: 10),
            _buildTableCell('', fontSize: 10),  // Middle separator
            _buildTableCell('Manager Signature', bold: true, fontSize: 10),
          ],
        ),
        // Signature row (empty space for signatures)
        pw.TableRow(
          children: [
            _buildTableCell(
              inspection.signature ?? '',
              fontSize: 14,
              bold: true,
              minHeight: 40,
            ),
            _buildTableCell('', fontSize: 14, minHeight: 40),  // Middle separator
            _buildTableCell('', fontSize: 14, minHeight: 40),
          ],
        ),
        // Date row
        pw.TableRow(
          children: [
            _buildTableCell('Date', fontSize: 10),
            _buildTableCell('', fontSize: 10),  // Middle separator
            _buildTableCell('Date', fontSize: 10),
          ],
        ),
      ],
    );
  }

  /// Helper: Build a table cell with optional formatting
  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    double fontSize = 8,
    bool centered = false,
    int colspan = 1,
    double? minHeight,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      constraints: minHeight != null ? pw.BoxConstraints(minHeight: minHeight) : null,
      child: pw.Align(
        alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Helper: Build a checkbox cell
  static pw.Widget _buildCheckboxCell(bool? checked) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Container(
        width: 10,
        height: 10,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
        ),
        child: checked == true
            ? pw.Center(
                child: pw.Text(
                  'X', // Changed to X to match typical forms if checkmark is not desired, or keep checkmark but smaller
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Helper: Build a checklist row with checkboxes
  static pw.TableRow _buildChecklistRow({
    required bool? leftCheckbox,
    required String leftText,
    required bool? rightCheckbox,
    required String rightText,
  }) {
    return pw.TableRow(
      children: [
        _buildCheckboxCell(leftCheckbox),
        _buildTableCell(leftText, fontSize: 8),
        _buildCheckboxCell(rightCheckbox),
        _buildTableCell(rightText, fontSize: 8),
      ],
    );
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

  /// Print inspection using template-matching PDF (offline, all platforms)
  static Future<void> printTemplateMatchingInspection(Inspection inspection) async {
    final pdfData = await generateTemplateMatchingPdf(inspection);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
    );
  }

  /// Share inspection using template-matching PDF (offline, all platforms)
  static Future<void> shareTemplateMatchingInspection(Inspection inspection) async {
    final pdfData = await generateTemplateMatchingPdf(inspection);
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

class _ChecklistItem {
  final String text;
  final bool? value;

  _ChecklistItem(this.text, this.value);
}
