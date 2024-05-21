import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_app/fullscreen.dart';
import 'package:flutter_app/report_detail.dart';

class StoreDetail extends StatefulWidget {
  final String reportId;
  final Report report;
  final int storeIndex;

  const StoreDetail({
    required this.reportId,
    required this.report,
    required this.storeIndex,
    super.key,
  });

  @override
  State<StoreDetail> createState() => _StoreDetailState();
}

class _StoreDetailState extends State<StoreDetail> {
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      broadcastReportListener;

  Report? report;
  bool isLoading = false;
  int currentSectionEditing = -1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final reportsStream = FirebaseFirestore.instance
        .doc('reports/${widget.reportId}')
        .snapshots();
    final broadcastReport = reportsStream.asBroadcastStream(
      onCancel: (controller) {
        print('Stream paused');
        controller.pause();
      },
      onListen: (controller) async {
        if (controller.isPaused) {
          print('Stream resumed');
          controller.resume();
        }
      },
    );
    broadcastReportListener = broadcastReport.listen(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.data() != null) {
        setState(() {
          report = Report.fromJson(snapshot.data()!, snapshot.id);
        });
      }
    }, onError: (e) {
      print('error in stream');
    });
  }

  @override
  void dispose() {
    broadcastReportListener.cancel();
    super.dispose();
  }

  void onEditSection(int sectionIdx) {
    setState(() {
      currentSectionEditing = sectionIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Store: ${widget.report.stores![widget.storeIndex].name}"),
      ),
      body: Stack(
        children: [
          (report == null || report?.stores == null)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            report!.stores![widget.storeIndex].sections.length,
                        itemBuilder: (ctx, sectionIdx) {
                          final bool isEditMode =
                              currentSectionEditing == sectionIdx;
                          var section = report!
                              .stores![widget.storeIndex].sections[sectionIdx];
                          final TextEditingController descriptionController =
                              TextEditingController(text: section.description);
                          final TextEditingController titleController =
                              TextEditingController(text: section.title);
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              borderOnForeground: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 160,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: section.images.length + 1,
                                          itemBuilder: (_, imageIdx) {
                                            return Builder(builder: (context) {
                                              return Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                                  child: imageIdx == 0
                                                      ? GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              isLoading = true;
                                                            });
                                                            await addImage(
                                                                sectionIdx);
                                                            setState(() {
                                                              isLoading = false;
                                                            });
                                                          },
                                                          child: SizedBox(
                                                            width: 160,
                                                            child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color
                                                                      .fromARGB(
                                                                          255,
                                                                          219,
                                                                          219,
                                                                          219),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                child: const Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(Icons
                                                                        .add_a_photo),
                                                                  ],
                                                                )),
                                                          ),
                                                        )
                                                      : GestureDetector(
                                                          onTap: () async {
                                                            if (isEditMode) {
                                                              setState(() {
                                                                isLoading =
                                                                    true;
                                                              });
                                                              await deleteImage(
                                                                  sectionIdx,
                                                                  imageIdx - 1);
                                                              setState(() {
                                                                isLoading =
                                                                    false;
                                                              });
                                                            } else {
                                                              Navigator.push(
                                                                context,
                                                                PageRouteBuilder(
                                                                  opaque: false,
                                                                  barrierColor:
                                                                      Colors
                                                                          .black,
                                                                  pageBuilder:
                                                                      (BuildContext
                                                                              context,
                                                                          _,
                                                                          __) {
                                                                    return FullScreenPage(
                                                                      dark:
                                                                          false,
                                                                      child: Image.network(section
                                                                              .images[
                                                                          imageIdx -
                                                                              1]),
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Container(
                                                              width: 200,
                                                              decoration:
                                                                  BoxDecoration(
                                                                image:
                                                                    DecorationImage(
                                                                  image:
                                                                      NetworkImage(
                                                                    section.images[
                                                                        imageIdx -
                                                                            1],
                                                                  ),
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                              child: isEditMode
                                                                  ? const Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child: Icon(
                                                                          Icons
                                                                              .delete,
                                                                          size:
                                                                              40,
                                                                          color:
                                                                              Colors.red),
                                                                    )
                                                                  : null,
                                                            ),
                                                          ),
                                                        ));
                                            });
                                          },
                                        ),
                                      ),
                                      if (isEditMode)
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: ElevatedButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStateProperty
                                                              .all(Colors.red)),
                                                  child: const Text('Remove Section',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  onPressed: () async {
                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                    await removeSection(
                                                        sectionIdx);
                                                    setState(() {
                                                      currentSectionEditing =
                                                          -1;
                                                      isLoading = false;
                                                    });
                                                  },
                                                ),
                                              )
                                            ]),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: TextField(
                                                    controller: titleController,
                                                    onSubmitted: (s) =>
                                                        editSectionFields(
                                                            sectionIdx,
                                                            titleController
                                                                .text,
                                                            descriptionController
                                                                .text),
                                                    decoration: const InputDecoration(
                                                        hintText:
                                                            'Section Name'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5),
                                                child: TextField(
                                                    controller:
                                                        descriptionController,
                                                    maxLines: 10,
                                                    keyboardType: TextInputType.multiline,
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1117707128.
                                                    textInputAction: TextInputAction.done,
                                                    decoration: const InputDecoration(
                                                        hintText:
                                                            'Section notes'),
                                                            onTapOutside: (s){
                                                              editSectionFields(
                                                            sectionIdx,
                                                            titleController
                                                                .text,
                                                            descriptionController
                                                                .text);},
                                                    onSubmitted: (s) =>
                                                        editSectionFields(
                                                            sectionIdx,
                                                            titleController
                                                                .text,
                                                            descriptionController
                                                                .text)),
                                              ),
                                            ]),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (isEditMode) {
                                            onEditSection(-1);
                                          } else {
                                            onEditSection(sectionIdx);
                                          }
                                        },
                                        child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              color: const Color.fromARGB(
                                                      255, 39, 39, 39)
                                                  .withOpacity(0.5),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Icon(
                                                  isEditMode
                                                      ? Icons.done
                                                      : Icons.edit,
                                                  size: 30,
                                                  color: isEditMode
                                                      ? Colors.green
                                                      : Colors.white),
                                            )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 50,
                      )
                    ],
                  ),
                ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Row(
          children: [
            Icon(Icons.add),
            Text('Add Section'),
          ],
        ),
        onPressed: () {
          onAddSection(widget.report, context);
        },
      ),
    );
  }

  Future<void> editSectionFields(
      int sectionIndex, String title, String description) async {
    Report newReport = report!;
    newReport.stores?[widget.storeIndex].sections[sectionIndex].title = title;
    newReport.stores?[widget.storeIndex].sections[sectionIndex].description =
        description;
    final newJsonObject = newReport.toJson();
    debugPrint(newJsonObject.toString());
    FirebaseFirestore.instance.doc('reports/${report!.id}').set(
          newJsonObject,
        );
    return;
  }

  Future<void> removeSection(int sectionIndex) async {
    Report newReport = report!;
    newReport.stores?[widget.storeIndex].sections.removeAt(sectionIndex);
    final newJsonObject = newReport.toJson();
    debugPrint(newJsonObject.toString());
    await FirebaseFirestore.instance.doc('reports/${report!.id}').set(
          newJsonObject,
        );
    return;
  }

  Future<void> deleteImage(int sectionIdx, int imageIdx) async {
    Report newReport = report!;
    newReport.stores?[widget.storeIndex].sections[sectionIdx].images
        .removeAt(imageIdx);
    final newJsonObject = newReport.toJson();
    debugPrint(newJsonObject.toString());
    return await FirebaseFirestore.instance.doc('reports/${report!.id}').set(
          newJsonObject,
          // SetOptions(merge: true),
        );
  }

  Future<bool> addImage(int sectionIndex) async {
    if (report != null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;

        // Upload file
        final res = await FirebaseStorage.instance
            .ref('uploads/$fileName')
            .putData(fileBytes);
        final image = await res.ref.getDownloadURL();
        print(image);
        Report newReport = report!;
        newReport.stores?[widget.storeIndex].sections[sectionIndex].images
            .insert(0, image);
        final newJsonObject = newReport.toJson();
        debugPrint(newJsonObject.toString());
        FirebaseFirestore.instance.doc('reports/${report!.id}').set(
              newJsonObject,
              // SetOptions(merge: true),
            );
        return true;
      }
      return false;
    }
    return false;
  }

  Future<void> createNewSection({
    required Report report,
    required String title,
  }) async {
    try {
      Report newReport = report;
      newReport.stores?[widget.storeIndex].sections
          .insert(0, Section(title: title));
      final newJsonObject = newReport.toJson();
      debugPrint(newJsonObject.toString());
      await FirebaseFirestore.instance.doc('reports/${report.id}').set(
            newJsonObject,
            // SetOptions(merge: true),
          );
    } catch (e) {}
  }

  Future<void> onAddSection(Report report, BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) {
          TextEditingController titleController = TextEditingController();
          FocusNode focusNode = FocusNode();
          focusNode.requestFocus();
          return AlertDialog(
            title: const Text('Add a Store Section'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Section Title'),
                  focusNode: focusNode,
                  onSubmitted: (s) {
                    createNewSection(
                      report: report,
                      title: titleController.text,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  createNewSection(
                    report: report,
                    title: titleController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              )
            ],
          );
        });
  }
}
