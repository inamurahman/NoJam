library globals;

import 'package:shared_preferences/shared_preferences.dart';

bool loggedIn = false;
double? mileage;
String? fuelType;

void loginUser() {
    loggedIn = true;
    saveGlobalsToPrefs();
    // Other login logic...
}

// Function to save globals data
Future<void> saveGlobalsToPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('loggedIn', loggedIn);
  prefs.setDouble('mileage', mileage ?? 0.0); // Provide a default value if mileage is null
  prefs.setString('fuelType', fuelType ?? ''); // Provide a default value if fuelType is null
}

// Function to load globals data
Future<void> loadGlobalsFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  loggedIn = prefs.getBool('loggedIn') ?? false;
  mileage = prefs.getDouble('mileage');
  fuelType = prefs.getString('fuelType');
}
