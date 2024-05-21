// Based on https://dartpad.dev/?id=d57c6c898dabb8c6fb41018588b8cf73
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/my_app.dart';

const Color darkBlue = Color.fromARGB(0, 47, 18, 43);

const messageLimit = 30;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e, st) {
    print(e);
    print(st);
  }

  // The first step to using Firebase is to configure it so that our code can
  // find the Firebase project on the servers. This is not a security risk, as
  // explained here: https://stackoverflow.com/a/37484053
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCoQ0rLcdElu0dLzPmdRnLuDPtN3vePo80",
      authDomain: "store-audit-a81b5.firebaseapp.com",
      projectId: "store-audit-a81b5",
      storageBucket: "store-audit-a81b5.appspot.com",
      messagingSenderId: "203426797072",
      appId: "1:203426797072:web:a558f4db79ffb290319c95",
      measurementId: "G-BV4NV2S9F9",
    ),
  );

  // We sign the user in anonymously, meaning they get a user ID without having
  // to provide credentials. While this doesn't allow us to identify the user,
  // this would, for example, still allow us to associate data in the database
  // with each user.
  // await FirebaseAuth.instance.signInAnonymously();

  runApp(MyApp(
    
  ));
}
