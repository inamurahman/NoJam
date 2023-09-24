import 'package:flutter/material.dart';
import 'package:nojam/get_details.dart'; // Import GetDetailPage from get_details.dart
import 'package:nojam/home.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: checkDetailsFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final bool detailsExist = snapshot.data ?? false;

            // Determine which page to navigate to based on file existence
            final initialRoute = detailsExist ? '/home' : '/getDetail';

            return MaterialApp(
              initialRoute: initialRoute, // Set the initial route
              routes: {
                '/home': (context) => HomePage(),
                '/getDetail': (context) => GetDetailPage(),
              },
              debugShowCheckedModeBanner: false,
            );
          } else {
            // Handle loading state here if needed
            return CircularProgressIndicator(); // Replace with appropriate widget
          }
        },
      ),
    );
  }

  Future<bool> checkDetailsFile() async {
    // Check if the your_detail.json file exists
    final file = File('your_detail.json');
    return await file.exists();
  }
}
