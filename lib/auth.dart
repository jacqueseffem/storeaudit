import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_app/my_app.dart';

class AuthPage extends StatelessWidget {
  AuthPage({super.key});

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          debugPrint('user: ${snapshot.data}');
          User? user;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            user = snapshot.data;
            if (user == null) {
              return Scaffold(
                  body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center),
                        const SizedBox(
                          width: double.infinity,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 270,
                      child: Column(
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(hintText: 'E-mail'),
                          ),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(hintText: 'Password'),
                            onSubmitted: (s) async {
                              final error = await loginWithEmailAndPassword(
                                email: emailController.text,
                                password: passwordController.text,
                              );
                              passwordController.text = '';
                              if (error != null) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            },
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      child: const Text('Login'),
                      onPressed: () async {
                        final error = await loginWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        passwordController.text = '';
                        if (error != null) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                    ),
                  ],
                ),
              ));
            } else {
              return ReportView(user: user);
            }
          }
        });
  }

  Future<String?> loginWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
