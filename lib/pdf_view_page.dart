import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/report_detail.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfViewPage extends StatefulWidget {
  final Report report;

  const PdfViewPage({Key? key, required this.report}) : super(key: key);

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late Future<Report> futureLoadedReport;

  @override
  void initState() {
    super.initState();
    futureLoadedReport = loadReport(widget.report);
  }

  Future<Report> loadReport(Report report) async {
    List<Store> newStoreObjects = [];
    for (Store store in report.stores ?? []) {
      final newFutureSections = store.sections.map((section) async {
        List<Uint8List> imageBytes = [];
        for (String imageUrl in section.images) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            imageBytes.add(response.bodyBytes);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
        return Section(
          title: section.title,
          images: section.images,
          description: section.description,
          imageBytes: imageBytes,
        );
      });
      final newSections = await Future.wait(newFutureSections);
      final newStore = Store(
        name: store.name,
        callOuts: store.callOuts,
        summary: store.summary,
        sections: newSections,
      );
      newStoreObjects.add(newStore);
    }
    return Report(
      id: report.id,
      name: report.name,
      created: report.created,
      stores: newStoreObjects,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Report>(
        future: futureLoadedReport,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return PdfPreview(build: (context) => makePdfDoc(snapshot.data!));
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

Future<Uint8List> makePdfDoc(Report loadedReport) async {
  
  final pdf = pw.Document();  

  for (Store store in loadedReport.stores ?? []) {
    final storePage = makePdfStorePage(store);
    pdf.addPage(storePage);
  }
  return pdf.save();
}

pw.Page makePdfStorePage(Store loadedStore) {
  debugPrint('makePdfStorePage store sections: ${loadedStore.sections.length}');
  return pw.Page(
    build: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Store Name
          pw.Text(loadedStore.name??'Unnamed Store'),

          // Store Sections
          for (Section section in loadedStore.sections)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(section.title??'Unnamed Section', style: pw.TextStyle(font: pw.Font.times())),
                pw.SizedBox(height: 10),
                // Images
                pw.SizedBox(
                  height: 100,
                  child: 
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    for (Uint8List imageBytes in section.imageBytes ?? [])
                      pw.Image(pw.MemoryImage(imageBytes)),
                  ]
                ),
                ),
                // Notes/Description
                pw.Text(section.description??'No Description'),
                pw.SizedBox(height: 20),
              ],
            ),
        ],
      );
    },
  );
}
