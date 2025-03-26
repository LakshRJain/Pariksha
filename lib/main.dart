import 'package:classcare/screens/getStarted.dart';
import 'package:classcare/screens/student/hometStudent.dart';
import 'package:classcare/screens/teacher/homeTeacher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Permission.storage.request();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Check user role if logged in
  Widget initialScreen = const Start();
  if (currentUser != null) {
    String? role = await getUserRole(currentUser.uid);
    if (role == 'Student') {
      initialScreen = const homeStudent();
    } else if (role == 'Teacher') {
      initialScreen = const TeacherDashboard();
    }
  }

  runApp(MyApp(initialScreen: initialScreen));
}

Future<String?> getUserRole(String userId) async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      return userDoc['role']; // Assumes Firestore has field 'role'
    }
  } catch (e) {
    print('Error getting user role: $e');
  }
  return null;
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/start':(context)=>Start(),
      },
      title: 'Pariksha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
