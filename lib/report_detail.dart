import 'dart:async';
import 'dart:developer';
// import 'dart:html';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_app/store_detail.dart';

class ReportDetail extends StatefulWidget {
  final String reportId;
  final String reportName;
  ReportDetail({
    required this.reportId,
    required this.reportName,
    super.key,
  });

  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail> {
  final TextEditingController controller = TextEditingController();
  int selectedStoreIndex = 0;
  bool isEditMode = false;

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }
  // late Stream<DocumentSnapshot<Map<String, dynamic>>>? _reportsStream;

  void onSearchNewStore(int storeIdx) {
    if (selectedStoreIndex != storeIdx) {
      setState(() {
        selectedStoreIndex = storeIdx;
      });
    }
  }

  Future<void> createNewStore({
    required Report report,
    required String title,
  }) async {
    try {
      Report newReport = report;
      newReport.stores?.insert(0, Store(name: title));
      final newJsonObject = newReport.toJson();
      debugPrint(newJsonObject.toString());
      await FirebaseFirestore.instance.doc('reports/${widget.reportId}').set(
            newJsonObject,
            // SetOptions(merge: true),
          );
    } catch (e) {}
  }

  Future<void> reset(String name) async {
    Map<String, dynamic> resetMap = {
      "name": "reportName",
      "created": 1,
      "stores": [
        {
          "name": "store name",
          "callOuts": {
            "title": "call out title",
            "images": ["imageUrl1", "imageUrl2"]
          },
          "sections": [
            {
              "title": "section title",
              "description": "section description",
              "images": [
                "https://th.bing.com/th/id/OIP.HJfQuiBxDZhHsEEXVviGgAHaE8?rs=1&pid=ImgDetMain",
                "https://th.bing.com/th/id/OIP.HJfQuiBxDZhHsEEXVviGgAHaE8?rs=1&pid=ImgDetMain"
              ]
            }
          ],
          "summary": {
            "description": "summary descrippy",
            "title": "summary title"
          },
        }
      ]
    };
    FirebaseFirestore.instance
        .doc('reports/${widget.reportId}')
        .set(resetMap, SetOptions(merge: true));
  }

  Future<void> onAddStore(BuildContext context, Report report) async {
    FocusNode focusNode = FocusNode();
    focusNode.requestFocus();
    await showDialog(
        context: context,
        builder: (context) {
          TextEditingController nameController = TextEditingController();
          return AlertDialog(
            title: Text('Add a Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  focusNode: focusNode,
                  decoration: InputDecoration(hintText: 'Store Name'),
                  onSubmitted: (s) async {
                    await createNewStore(
                    report: report,
                    title: nameController.text,
                  );
                  Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await createNewStore(
                    report: report,
                    title: nameController.text,
                  );
                  Navigator.pop(context);
                },
                child: Text('Add'),
              )
            ],
          );
        });
  }

  Future<void> onDeleteStore(Report report, int storeIndex) async {
    try {
      Report newReport = report;
      newReport.stores?.removeAt(storeIndex);
      final newJsonObject = newReport.toJson();
      debugPrint(newJsonObject.toString());
      await FirebaseFirestore.instance.doc('reports/${widget.reportId}').set(
            newJsonObject,
            // SetOptions(merge: true),
          );
    } catch (e) {}
  }

  void goToStoreDetail(
    String reportId,
    Report report,
    int storeIndex,
  ) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return StoreDetail(
        reportId: reportId,
        report: report,
        storeIndex: storeIndex,
      );
    }));
  }

  Report? report;
  bool isLoading = true;
  String? error;
  List<DropdownMenuEntry<int>> storesDropdownEntry = [];
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      broadcastReportListener;

  @override
  void dispose() {
    broadcastReportListener.cancel();
    super.dispose();
  }

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
        report = Report.fromJson(snapshot.data()!, snapshot.id);
        int counter = 0;
        setState(() {
          storesDropdownEntry = [];
        });
        for (Store store in report?.stores ?? []) {
          storesDropdownEntry.add(DropdownMenuEntry(
              label: store.name ?? 'Unknown', value: counter));
          counter++;
        }
        isLoading = false;
        setState(() {});
      }
    }, onError: (e) {
      print('error in stream');
      setState(() {
        error = e.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.reportName),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                child: Center(
                    child: isEditMode
                        ? Text('Done',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : Icon(Icons.edit, color: Colors.white)),
                onTap: () {
                  toggleEditMode();
                },
              ),
            )
          ],
        ),
        body: Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 0),
            child: Builder(builder: (context) {
              if (isLoading || report == null) {
                return Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Stores',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    if (report != null && report!.stores != null)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: report!.stores!.length,
                        itemBuilder: (_, index) {
                          return Card(
                            child: ListTile(
                              onTap: () async {
                                if (isEditMode) {
                                  bool? res = await showDialog(
                                      context: context,
                                      builder: (builder) {
                                        return AlertDialog(
                                          content: Text(
                                              "Delete Store: '${report!.stores![index].name}' ?",
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          actions: [
                                            TextButton(
                                                child: Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, true);
                                                })
                                          ],
                                        );
                                      });
                                  if (res != null && res) {
                                    onDeleteStore(report!, index);
                                  }
                                } else {
                                  goToStoreDetail(
                                      widget.reportId, report!, index);
                                }
                              },
                              title: Text(
                                report?.stores?[index].name ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: isEditMode
                                  ? Icon(Icons.delete, color: Colors.red)
                                  : Icon(Icons.arrow_forward_ios,
                                      color: Colors.black),
                            ),
                          );
                        },
                      ),
                    // if (report?.stores != null && report!.stores!.isNotEmpty)
                  ],
                ),
              );
            })),
        floatingActionButton: report != null
            ? FloatingActionButton.extended(
                onPressed: () => onAddStore(context, report!),
                label: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    Text('Add New Store',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              )
            : null);
  }
}

class Report {
  final String id;
  final String? name;
  final List<Store>? stores;
  final int? created;

  Report(
      {required this.name,
      required this.stores,
      required this.created,
      required this.id});

  factory Report.fromJson(Map<String, dynamic> json, String id) {
    return Report(
      id: id,
      name: json['name'],
      stores: List<Store>.from(
          (json['stores'] ?? []).map((store) => Store.fromJson(store))),
      created: json['created'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stores': stores?.map((store) => store.toJson()).toList(),
      'created': created,
    };
  }
}

class Store {
  final List<Section> sections;
  final CallOut? callOuts;
  final String? name;
  final Summary? summary;

  Store({this.sections = const [], this.callOuts, this.name, this.summary});

  factory Store.fromJson(Map<String, dynamic> json) {
    List<Section> _sections = [];
    for (Map<String, dynamic> section in json['sections'] ?? []) {
      final sec = Section.fromJson(section);
      _sections.add(sec);
    }
    return Store(
      sections: _sections,
      callOuts: CallOut.fromJson(json['callOuts'] ?? {}),
      name: json['name'],
      summary: Summary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((section) => section.toJson()).toList(),
      'callOuts': callOuts?.toJson(),
      'name': name,
      'summary': summary?.toJson(),
    };
  }
}

class Section {
  String? title;
  List<String> images;
  String? description;

  Section({
    this.title,
    this.images = const [],
    this.description,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    try {
      return Section(
        title: json['title'],
        images: List<String>.from(json['images'] ?? []),
        description: json['description'],
      );
    } catch (e) {
      return Section();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'images': images,
      'description': description,
    };
  }
}

class CallOut {
  final String? title;
  final List<String> images;

  CallOut({required this.title, required this.images});

  factory CallOut.fromJson(Map<String, dynamic> json) {
    return CallOut(
      title: json['title'],
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'images': images,
    };
  }
}

class Summary {
  final String? description;
  final String? title;

  Summary({required this.description, required this.title});

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      description: json['description'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'title': title,
    };
  }
}
