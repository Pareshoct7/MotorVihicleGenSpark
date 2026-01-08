import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PdfViewerScreen extends StatelessWidget {
  final File file;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.file,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: PdfPreview(
        build: (format) => file.readAsBytes(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat(
          21.0 * PdfPageFormat.cm,
          29.7 * PdfPageFormat.cm,
          marginAll: 0,
        ),
      ),
    );
  }
}
