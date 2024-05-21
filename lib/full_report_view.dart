import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/report_detail.dart';
// import 'package:screenshot/screenshot.dart';

class FullReportViewPage extends StatefulWidget {
  final Report report;
  const FullReportViewPage({required this.report, super.key});

  @override
  State<FullReportViewPage> createState() => _FullReportViewPageState();
}

class _FullReportViewPageState extends State<FullReportViewPage> {
  Uint8List? imageFile;

  late Report report;


  // ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    report = widget.report;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.name ?? 'Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Report ID: ${report.id}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Created: ${report.created}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            report.stores != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.stores!.map((store) => buildStoreWidget(store)).toList(),
                  )
                : Text('No stores available'),
          ],
        ),
      ),
    );
  }

  Widget buildStoreWidget(Store store) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store Name: ${store.name ?? 'Unknown'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            (store.callOuts != null || store.callOuts?.title != null) ? buildCallOutWidget(store.callOuts!) : Container(),
            // store.summary != null ? buildSummaryWidget(store.summary!) : Container(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: store.sections.map((section) => buildSectionWidget(section)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCallOutWidget(CallOut callOut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CallOut: ${callOut.title?? ''}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Column(
          children: callOut.images.map((image) => Image.network(image)).toList(),
        ),
      ],
    );
  }

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

  Widget buildSectionWidget(Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section: ${section.title}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(section.description ?? 'No description'),
        Column(
          children: section.images.map((image) => Image.network(image)).toList(),
        ),
      ],
    );
  }
}