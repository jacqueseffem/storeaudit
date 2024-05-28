import 'dart:convert';
import 'dart:developer';
import 'dart:io';
// import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pdf_view_page.dart';
import 'package:flutter_app/report_detail.dart';
import 'package:image_network/image_network.dart';
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
  bool loading = false;
  String? downloadUrl;

  late Report report;
  late final reportWidget;

  ScreenshotController screenshotController = ScreenshotController();

// Suggested code may be subject to a license. Learn more: ~LicenseLog:340142623.
  

  @override
  void initState() {
    super.initState();
    report = widget.report;
    reportWidget = FullReportWidget(
    report: report
  );
  }

  _goToPdfPage(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewPage(
          report: report,
        ),
      ),
    );
  }

  buildPdf() async {
    setState(() {
      loading = true;
    });
    try {
      await screenshotController
          .captureFromLongWidget(
        pixelRatio: 2,
        InheritedTheme.captureAll(
          context,
          Material(
            child: reportWidget,
          ),
        ),
        delay: const Duration(milliseconds: 3500),
        context: context,
      )
          .then((image) async {
        final url = await getDownloadUrl(image,
            downloadName: widget.report.name ?? 'report',
            contentType: 'image/png');
        setState(() {
          loading = false;
          _showErrorSnackbar('Image Generated: $url');
          if (url != null) {
            downloadUrl = url;
          }
        });
        await _openUrl(downloadUrl!);
      });
    } catch (e) {
      log(e.toString());
      setState(() {
        loading = false;
      });
      _showErrorSnackbar(e.toString());
    }
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
    return pdfUrl;
  }

  _openUrl(String url) async {
    Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
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
        actions: [
          IconButton(
            onPressed: () {
              if (loading) {
                return;
              }
              if (downloadUrl == null) {
                buildPdf();
              } else {
                _openUrl(downloadUrl!);
              }
            },
            icon: loading
                ? const CircularProgressIndicator()
                : const Icon(CupertinoIcons.printer),
          ),
          IconButton(
            onPressed: () {
              _goToPdfPage(report);
            },
            icon: const Icon(CupertinoIcons.doc_text_fill),
          ),
        ],
      ),
      body: SingleChildScrollView(child: reportWidget),
    );
  }
}

class FullReportWidget extends StatelessWidget {
  final double? width;

  const FullReportWidget({
    super.key,
    this.width,
    required this.report,
  });

  final Report report;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text('${report.name}',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(color: Colors.black)),

            // Date
            report.created != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          _dateTimeToHuman(DateTime.fromMillisecondsSinceEpoch(
                              report.created!)),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(color: Colors.black)),
                      const SizedBox(height: 20),
                    ],
                  )
                : const SizedBox.shrink(),

            // Date

            // Stores
            Text('${report.stores?.length ?? ''} Store(s)',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(color: Colors.black)),
            const SizedBox(height: 20),
            for (Store store in report.stores ?? [])
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 40),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                      ),
                      // Store Name
                      Text(store.name ?? 'Unnamed Store',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      // Store Sections
                      for (Section section in store.sections)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Section Title
                            Text(section.title ?? 'Unnamed Section',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            // Section Images

                            Wrap(
                              alignment: WrapAlignment.start,
                              children: [
                                for (String image in section.images)
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: 
                                      ImageNetwork(
                                        image: image,
                                        width: 160,
                                        height: 200,
                                        fitWeb: BoxFitWeb.cover,
                                        fitAndroidIos: BoxFit.cover,

                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            // Section Description
                            Text(
                              section.description ?? 'No Notes',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 92, 92, 92)),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      // Call Out
                      // Summary
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

String _dateTimeToHuman(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
