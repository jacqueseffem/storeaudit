import 'dart:convert';
import 'dart:developer';
import 'dart:io';
// import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/report_detail.dart';
// import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';

class FullReportViewPage extends StatefulWidget {
  final Report report;
  const FullReportViewPage({required this.report, super.key});

  @override
  State<FullReportViewPage> createState() => _FullReportViewPageState();
}

class _FullReportViewPageState extends State<FullReportViewPage> {
  Uint8List? imageFile;
  final pdf = pw.Document();
  String status = 'not started';
  String? downloadUrl;

  late Report report;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    report = widget.report;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await buildPdf();
    });
  }

  buildPdf() async {
    setState(() {
      status = 'building';
    });
    screenshotController.capture().then((image) async {
      if (image == null) {
        setState(() {
          status = 'No image';
        });
        return;
      }
      await getDownloadUrl(image,
          downloadName: widget.report.name ?? 'report', contentType: 'image/png');
      setState(() {
        status = 'Saved!';
        imageFile = image;
      });
    }).catchError((onError) {
      print(onError);
    });
//     try {
//       final fullPage = await buildFullList();
//       final font = await PdfGoogleFonts.cardoRegular();
//       pdf.addPage(
//         pw.Page(
// // Suggested code may be subject to a license. Learn more: ~LicenseLog:4062197564.
//           theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: font)),
//           pageFormat: PdfPageFormat.a4,
//           build: (pw.Context context) {
//             return pw.Center(
//               child: fullPage,
//             ); // Center
//           },
//         ),
//       ); //

//       final bytes = await pdf.save();
//       final url = await getDownloadUrl(bytes,
//           downloadName: widget.report.name ?? 'report');
//       setState(() {
//         status = 'Saved!';
//         downloadUrl = url;
//       });
//       debugPrint('Saved!: $url');
//     } catch (e, s) {
//       setState(() {
//         status = 'error building pdf ${e.toString()}, stack: $s';
//       });
//     }
  }

  Future<String?> getDownloadUrl(
    Uint8List file, {
    required String downloadName,
    String contentType = 'application/pdf',
  }) async {
    // Upload to firebase storage
    final res = await FirebaseStorage.instance
        .ref('uploads/$downloadName')
        .putData(file, SettableMetadata(contentType: contentType));
    // Get url
    final pdfUrl = await res.ref.getDownloadURL();
    // Open in browser
    // html.window.open(pdfUrl, '_blank');
    return pdfUrl;
  }

  _openUrl(String url) async {
    Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackbar('Could not open url');
    }
  }

  _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(report.name ?? 'Report Details'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(status),
              downloadUrl == null
                  ? SizedBox()
                  : ElevatedButton(
                      onPressed: () {
                        _openUrl(downloadUrl!);
                      },
                      child: Text('View PDF'))
            ],
          ),
        ),
      ),
    );
  }

  Future<pw.Widget> buildFullList() async {
    List<pw.Widget> storeWidgets = [];
    for (var store in report.stores ?? []) {
      storeWidgets.add(await buildStoreWidget(store));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${report.name}',
            style: pw.TextStyle(fontSize: 24, font: pw.Font.courier())),
        // pw.SizedBox(height: 8),
        // pw.Text('Created: ${report.created}',
        //     style: pw.TextStyle(fontSize: 16, font: pw.Font.courier())),
        pw.SizedBox(height: 8),
        pw.Text('${report.stores?.length ?? ''} Store(s)',
            style: pw.TextStyle(fontSize: 16, font: pw.Font.courier())),
        pw.SizedBox(height: 20),
        report.stores != null
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: storeWidgets,
              )
            : pw.Text('No stores available',
                style: pw.TextStyle(fontSize: 12, font: pw.Font.courier())),
      ],
    );
  }

  Future<pw.Widget> buildStoreWidget(Store store) async {
    List<pw.Widget> sections = [];
    for (var section in store.sections) {
      try {
        final sec = await buildSectionWidget(section);
        sections.add(sec);
        debugPrint('Built section: ${section.title} in store ${store.name}');
      } catch (e) {
        debugPrint('Error building section: $e');
        continue;
      }
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('Store Name: ${store.name ?? 'Unknown'}',
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.courier())),
        pw.SizedBox(height: 8),
        // (store.callOuts != null || store.callOuts?.title != null) ? buildCallOutWidget(store.callOuts!) : Container(),
        // // store.summary != null ? buildSummaryWidget(store.summary!) : Container(),
        ...sections,
      ],
    );
  }

  // pw.Widget buildCallOutWidget(CallOut callOut) {
  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Text('CallOut: ${callOut.title?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
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
  //       Text('Summary: ${summary.title}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, font: pw.Font.courier())),
  //       SizedBox(height: 8),
  //       Text(summary.description ?? 'No description', font: pw.Font.courier()),
  //     ],
  //   );
  // }

  Future<pw.Widget> buildSectionWidget(Section section) async {
    List sectionImages = [];
    for (var imageUrl in section.images) {
      // final netImage = await networkImage(imageUrl);
      // sectionImages
      //     .add(pw.Image(netImage, fit: pw.BoxFit.contain, height: 200));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('Section: ${section.title}',
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.courier())),
        pw.SizedBox(height: 8),
        pw.Text(section.description ?? 'No notes',
            style: pw.TextStyle(font: pw.Font.courier())),
        // pw.Column(
        //   children:
        //       sectionImages.map((image) => pw.Image(image.image)).toList(),
        // ),
        pw.SizedBox(
          height: 30,
        ),
      ],
    );
  }
}
