import 'dart:developer';

import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/auth.dart';
import 'package:flutter_app/profile.dart';
import 'package:flutter_app/report_detail.dart';
import 'package:intl/intl.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color.fromARGB(255, 0, 0, 160),
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 0, 0, 160),
        cardColor: const Color.fromARGB(255, 233, 233, 233),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 0, 215, 185),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
          ),
          
        ),
        fontFamilyFallback: ['Arial'],
      ),
      home: FlutterSplashScreen.fadeIn(
        backgroundColor: Colors.white,
        onInit: () {
          debugPrint("On Init");
        },
        onEnd: () {
          debugPrint("On End");
        },
        childWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    "assets/mars-logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Text('Field Sales - Store Audit Tool',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
          ],
        ),
        onAnimationEnd: () => debugPrint("On Fade In End"),
        nextScreen: AuthPage(),
      ),
    );
  }
}

class ReportView extends StatelessWidget {
  const ReportView({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    "assets/mars-logo.png",
                    fit: BoxFit.cover,
                    height: 40,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    onProfilePicTap(context);
                  },
                  child: user.photoURL != null
                      ? CircleAvatar(
                          maxRadius: 25,
                          foregroundImage: NetworkImage(user.photoURL!))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            'assets/anon-image.jpg',
                            height: 40,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Reports',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .orderBy('created', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('$snapshot.error'));
                  } else if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  final reports = <Report>[];
                  for (final doc in docs) {
                    reports.add(Report.fromJson(
                        doc.data() as Map<String, dynamic>, doc.id));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final report = reports[index];
                      return Dismissible(
                        key: Key(report.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          deleteReport(report.id);
                        },
                        confirmDismiss: (direc) async {
                          bool? res = await showDialog(
                              context: context,
                              builder: (builder) {
                                return AlertDialog(
                                  content: Text(
                                      "Delete Report: '${report.name} ?",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  actions: [
                                    TextButton(
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        })
                                  ],
                                );
                              });
                          if (res != null && res) {
                            return true;
                          }
                          return null;
                        },
                        background: Container(
                          color: Colors.red,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        child: Card(
                          child: ListTile(
                            onTap: () {
                              goToReport(report.id, report.name ?? '', context);
                            },
                            title: Text(report.name ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: (report.created != null &&
                                    report.created! > 100000000)
                                ? Text(DateFormat('dd/MM/yyyy').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        report.created!)))
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.black),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onTapAddReport(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void onProfilePicTap(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) {
      return ProfilePage();
    }));
  }

  void goToReport(String reportId, String reportName, BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) {
      return ReportDetail(reportId: reportId, reportName: reportName);
    }));
  }

  void onTapAddReport(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) {
          TextEditingController nameController = TextEditingController();
          FocusNode node = FocusNode();
          node.requestFocus();
          return AlertDialog(
            title: const Text('Create a report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  focusNode: node,
                  decoration: const InputDecoration(hintText: 'Name Name'),
                  onSubmitted: (s) => createReport(s),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await createReport(nameController.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              )
            ],
          );
        });
  }

  void deleteReport(String docId) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).delete();
  }

  Future<void> createReport(String reportName) async {
    await FirebaseFirestore.instance.collection('reports').add({
      "created": DateTime.now().millisecondsSinceEpoch,
      "name": reportName,
      "stores": []
    });
  }
}
