import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User? user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    user = _auth.currentUser;
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user?.email}', style: TextStyle(fontSize: 35)),
            SizedBox(
              height: 15,
            ),
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
                _logout();

              },
              child: Text('Logout'),
            ),
          ],
        ),
      )
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }
}