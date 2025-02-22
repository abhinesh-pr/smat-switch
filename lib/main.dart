
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'appnew.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: SwitchifyDashboard(),
      )
  );
}
