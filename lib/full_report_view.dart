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
      final url = await getDownloadUrl(image,
          downloadName: widget.report.name ?? 'report', contentType: 'image/png');
      setState(() {
        status = 'Saved!';
        downloadUrl = url;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(report.name ?? 'Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: FullReportWidget(report: report)),
      ),
    );
  }
}

class FullReportWidget extends StatelessWidget {
  const FullReportWidget({
    super.key,
    required this.report,
  });

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    
        // Title
        Text('${report.name}', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black)),
        SizedBox(height: 0),
    
        // Date
        report.created!=null?
        Column(
          children: [
            Text(_dateTimeToHuman(DateTime.fromMillisecondsSinceEpoch(report.created!)), style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black)),
            SizedBox(height: 20),
          ],
        ):SizedBox(),
        
    
        // Date
    
        // Stores
        Text('${report.stores?.length??''} Store(s)', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black)),
        SizedBox(height: 20),
        for (Store store in report.stores??[])
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(bottom: 40),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                  ),
                  // Store Name
                  Text(store.name??'Unnamed Store', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  // Store Sections
                  for (Section section in store.sections)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Text(section.title??'Unnamed Section', style: TextStyle(fontWeight: FontWeight.bold)),
                        // Section Images
                        for (String image in section.images)
                          Image.network(image, height: 200, width: 200),
                        // Section Description
                        Text(section.description??'No Notes', style: TextStyle(color: const Color.fromARGB(255, 92, 92, 92)),),
                        SizedBox(height: 15),
                      ],
                    ),	
                  // Call Out
                  // Summary
                ],
              ),
            ),
          )  
      ],
    );
  }
}

String _dateTimeToHuman(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}