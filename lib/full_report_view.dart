import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/report_detail.dart';
// import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FullReportViewPage extends StatefulWidget {
  final Report report;
  const FullReportViewPage({required this.report, super.key});

  @override
  State<FullReportViewPage> createState() => _FullReportViewPageState();
}

class _FullReportViewPageState extends State<FullReportViewPage> {
  Uint8List? imageFile;
  final pdf = pw.Document();

  late Report report;

  // ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    report = widget.report;
    buildPdf();
  }

  buildPdf() async {
    final fullPage = await buildFullList();
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: fullPage,
          ); // Center
        })); //
    final file = File("fullreport.pdf");
    await file.writeAsBytes(await pdf.save());
    log('Saved!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.name ?? 'Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Exporting...'),
      ),
    );
  }

  Future<pw.Widget> buildFullList() async {
    List<pw.Widget> storeWidgets = [];
    for (var store in report.stores ?? []) {
      storeWidgets.add(await buildStoreWidget(store));
    }
    return pw.ListView(
      children: [
        pw.Text('Report ID: ${report.id}', style: pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Text('Created: ${report.created}',
            style: pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 8),
        report.stores != null
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: storeWidgets,
              )
            : pw.Text('No stores available'),
      ],
    );
  }

  Future<pw.Widget> buildStoreWidget(Store store) async {
    List<pw.Widget> sections = [];
    for (var section in store.sections) {
      sections.add(await buildSectionWidget(section));
    }
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(16.0),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Store Name: ${store.name ?? 'Unknown'}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            // (store.callOuts != null || store.callOuts?.title != null) ? buildCallOutWidget(store.callOuts!) : Container(),
            // // store.summary != null ? buildSummaryWidget(store.summary!) : Container(),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: sections),
          ],
        ),
      ),
    );
  }

  // pw.Widget buildCallOutWidget(CallOut callOut) {
  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Text('CallOut: ${callOut.title?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
  //       pw.SizedBox(height: 8),
  //       pw.Column(
  //         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //         children: callOut.images.map((image) {
  //           final netImage = await networkImage()
  //           return pw.Padding(
  //           padding: const pw.EdgeInsets.all(8.0),
  //           child: pw.Image(image, fit: BoxFit.contain, height: 200),
  //         )).toList(),
  //       ),
  //     ],
  //   );
  // }

  // Widget buildSummaryWidget(Summary summary) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Summary: ${summary.title}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //       SizedBox(height: 8),
  //       Text(summary.description ?? 'No description'),
  //     ],
  //   );
  // }

  Future<pw.Widget> buildSectionWidget(Section section) async {
    final sectionImages =
        await Future.wait(section.images.map((imageUrl) async {
      final netImage = await networkImage(imageUrl);
      return pw.Image(netImage, fit: pw.BoxFit.contain, height: 200);
    }).toList());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Section: ${section.title}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(section.description ?? 'No description'),
        pw.Column(
          children:
              sectionImages.map((image) => pw.Image(image.image)).toList(),
        ),
      ],
    );
  }
}
