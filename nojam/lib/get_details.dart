import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:nojam/home.dart';
import 'package:nojam/my-globals.dart' as globals;

/*
void GetDetailPage() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GetDetailPage(),
    ),
  );
}
*/

class GetDetailPage extends StatelessWidget {
  //const GetDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CarbonFootprintCalculator(),
    );
  }
}

class CarbonFootprintCalculator extends StatefulWidget {
  @override
  _CarbonFootprintCalculatorState createState() =>
      _CarbonFootprintCalculatorState();
}

class _CarbonFootprintCalculatorState extends State<CarbonFootprintCalculator> {
  String selectedFuelType = 'Petrol';
  String mileage = '';
  double CFS = 0.0;

  @override
  void initState() {
    super.initState();
    // Load previously stored values from JSON file
    loadValuesFromJsonFile();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carbon Footprint Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: selectedFuelType,
              onChanged: (newValue) {
                setState(() {
                  selectedFuelType = newValue!;
                });
                // Save the selectedFuelType to SharedPreferences
                saveValueToSharedPreferences('fuelType', selectedFuelType);
              },
              items: <String>['Petrol', 'Diesel']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}$')),
              ],
              onChanged: (value) {
                setState(() {
                  mileage = value;
                });
                // Save the mileage to SharedPreferences
                
                saveValueToSharedPreferences('mileage', mileage);
              },
              decoration: InputDecoration(
                labelText: 'Enter Mileage (km/L)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  /*
                  CFS = calculateCarbonFootprint(
                      10.0, double.tryParse(mileage) ?? 0.0, selectedFuelType);
                  */
                  // Call the method to save data to JSON here
                  saveValuesToJsonFile();
                  globals.mileage = double.tryParse(mileage);
                  globals.fuelType = selectedFuelType;
                  globals.loginUser();
                  // Example: When the user logs in successfully, set loggedIn to true and save it.
                  

                });

                // Redirect to HomePage
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
  /*
  double calculateCarbonFootprint(
      double distance, double mileage, String fuelType) {
    double emissionsFactor = (fuelType == 'Petrol') ? 2.2 : 2.8;
    return (distance / mileage) * emissionsFactor;
  }
  */
// Modify this function to save data to a JSON file
  Future<void> saveValuesToJsonFile() async {
    final data = {
      'fuelType': selectedFuelType,
      'mileage': mileage,
    };
    final jsonEncoded = jsonEncode(data);

    final file = File('your_data.json'); // Change the filename as needed
    await file.writeAsString(jsonEncoded);
  }

  Future<void> saveValueToSharedPreferences(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  // Modify this function to load data from the JSON file
  Future<Map<String, dynamic>> loadValuesFromJsonFile() async {
  try {
    final file = File('your_data.json'); // Change the filename as needed
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString);
    return data;
  } catch (e) {
    // Handle errors such as file not found or invalid JSON
    print('Error loading data: $e');
    return {}; // Return an empty map in case of an error
  }
}
}