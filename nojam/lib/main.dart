import 'package:flutter/material.dart';
import 'package:nojam/get_details.dart'; // Import GetDetailPage from get_details.dart
import 'package:nojam/home.dart';
import 'dart:io';
import 'package:nojam/my-globals.dart'; // Import the modified globals.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initialRoute = loggedIn ? '/home' : '/getDetail'; // Determine the initial route based on loggedIn

    return MaterialApp(
      initialRoute: initialRoute, // Set the initial route
      routes: {
        '/home': (context) => HomePage(),
        '/getDetail': (context) => GetDetailPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<bool> checkDetailsFile() async {
  // Check if the your_detail.json file exists
  final file = File('your_detail.json');
  return await file.exists();
}
