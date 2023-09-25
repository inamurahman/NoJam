  import 'package:flutter/material.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:pedometer/pedometer.dart';
  import 'dart:convert';
  import 'dart:io';
  import 'package:path_provider/path_provider.dart';
  import 'package:fl_chart/fl_chart.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'get_details.dart'; // Import get_details.dart
  import 'my-globals.dart' as globals;

  class StorageManager {
    Future<String> get downloadsPath async {
      final directory = await getExternalStorageDirectory();
      return directory!.path;
    }

    Future<File> get downloadDataFile async {
      final path = await downloadsPath;
      return File('$path/distance_data.json'); // Change the filename as needed
    }

    Future<File> get downloadReductionFile async {
      final path = await downloadsPath;
      return File('$path/reduction_data.json'); // Change the filename as needed
    }

    Future<Map<String, dynamic>> readData() async {
      try {
        final file = await downloadDataFile;
        String contents = await file.readAsString();
        return json.decode(contents);
      } catch (e) {
        return {};
      }
    }

    Future<File> writeData(Map<String, dynamic> data) async {
      final file = await downloadDataFile;
      return file.writeAsString(json.encode(data));
    }

    Future<double> readTotalReduction() async {
      try {
        final file = await downloadReductionFile;
        String contents = await file.readAsString();
        return double.parse(contents);
      } catch (e) {
        return 0; // Return 0 if the file doesn't exist or an error occurs
      }
    }

    Future<File> writeTotalReduction(double amount) async {
      final file = await downloadReductionFile;
      return file.writeAsString('$amount');
    }
  }


  class DistanceChart extends StatelessWidget {
    final Map<String, dynamic> data;
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    DistanceChart({required this.data});

    @override
    Widget build(BuildContext context) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values
              .fold(0.0, (prev, curr) => prev + curr['walking'] + curr['cycling'])
              .toDouble(),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xff37434d),
              width: 1.0,
            ),
          ),
          barGroups: data.keys.map((date) {
            return BarChartGroupData(
              x: DateTime.parse(date).weekday.toDouble().toInt(), // Convert to int
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: data[date]['walking'].toDouble(),
                  color: Colors.blue,
                ),
                BarChartRodData(
                  fromY: 0,
                  toY: data[date]['cycling'].toDouble(),
                  color: Colors.green,
                ),
              ],
            );
          }).toList(),
        ),
      );
    }
  }

  class LocationTracker extends StatefulWidget {
    @override
    _LocationTrackerState createState() => _LocationTrackerState();
  }

  class _LocationTrackerState extends State<LocationTracker> {
    String _locationInfo = 'Location unavailable';
    String _stepCount = 'Steps: 0';
    String _transportMode = 'Unknown';
    int _totalSteps = 0;
    double _totalDistance = 0.0;
    double _totalWalkedDistance = 0.0;
    double _totalCycledDistance = 0.0;
    double _totalMotorVehicleDistance = 0.0;

    Position? _previousPosition;
    final StorageManager storage = StorageManager();
    Map<String, dynamic> _weeklyData = {};
    double _totalReduction = 0.0; // Store the total reduction

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

    double? mileage;
    String? selectedFuelType;

    @override
    void initState() {
      super.initState();
      _checkLocationPermission();
      _startTrackingSteps();
      // Load mileage and selectedFuelType from get_details.dart
      loadValuesFromJsonFile().then((values) {
        setState(() {
          mileage = values['mileage'];
          globals.mileage = mileage;
          selectedFuelType = values['selectedFuelType'];
          globals.fuelType = selectedFuelType;
        });
      });
      // Load the total reduction when initializing the state
      storage.readTotalReduction().then((reduction) {
        if (reduction != null && !reduction.isInfinite) {
          setState(() {
            _totalReduction = reduction;
          });
        }
      });

    }

    void _checkLocationPermission() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _requestLocationPermission();
      } else {
        _startTrackingLocation();
      }
    }

    void _requestLocationPermission() async {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationInfo = 'Location permission denied';
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationInfo = 'Location permission permanently denied';
        });
      } else {
        _startTrackingLocation();
      }
    }

    void _startTrackingLocation() {
      Geolocator.getPositionStream().listen((Position updatedPosition) {
        if (_previousPosition != null) {
          double distance = Geolocator.distanceBetween(
            _previousPosition!.latitude,
            _previousPosition!.longitude,
            updatedPosition.latitude,
            updatedPosition.longitude,
          );

          double speed = distance; // Assuming update interval is every second

          if (speed < 0.3) {
            _transportMode = 'Stationary';
          } else if (speed < 9) {
            _transportMode = 'Walking';
            _totalWalkedDistance += distance;
          } else if (speed >= 9 && speed < 13) {
            _transportMode = 'Cycling';
            _totalCycledDistance += distance;
          } else {
            _transportMode = 'Motor-vehicle';
            _totalMotorVehicleDistance += distance;
          }

          _totalDistance += distance;

          

          String today = DateTime.now().toIso8601String().split('T')[0];
          storage.readData().then((data) {
            if (!data.containsKey(today)) {
              data[today] = {'walking': 0.0, 'cycling': 0.0, 'motor-vehicle': 0.0};
            }
            data[today][_transportMode.toLowerCase()] += distance;
            storage.writeData(data);

            setState(() {
              _weeklyData = data;
            });
          });
          
          
          // Calculate the total reduction when tracking location
          double totalReduction = calculateTotalReduction(globals.mileage ?? 10, globals.fuelType ?? 'Petrol');
          _storeTotalReduction(totalReduction);
        }

        setState(() {
          _locationInfo =
              'Latitude: ${updatedPosition.latitude}, '
              'Longitude: ${updatedPosition.longitude}\n'
              'Walked: ${_totalWalkedDistance.toStringAsFixed(2)} m\n'
              'Cycled: ${_totalCycledDistance.toStringAsFixed(2)} m\n'
              'Mode: $_transportMode';
          _previousPosition = updatedPosition;
        });
      });
    }

    void _startTrackingSteps() {
  setState(() {
    _totalSteps = 0; // Reset the step count to 0
    _stepCount = 'Steps: 0';
  });

  Pedometer.stepCountStream.listen((StepCount event) {
    setState(() {
      _totalSteps = event.steps;
      _stepCount = 'Steps: $_totalSteps';
    });
  }, onError: (error) {
    print("Error in step count: $error");
  });

  // Optionally, you can also save the reset step count to a file or storage here.
}


    double calculateCarbonFootprint(double distance, double mileage, String fuelType) {
      // Check if distance, mileage, or emissionsFactor is Infinity or NaN
      if (distance.isInfinite || distance.isNaN || mileage.isInfinite || mileage.isNaN) {
        return 0.0; // Handle the case where inputs are not valid
      }

      double emissionsFactor = (fuelType == 'Petrol') ? 2.2 : 2.8;
    
      // Check if emissionsFactor is Infinity or NaN
      if (emissionsFactor.isInfinite || emissionsFactor.isNaN) {
        return 0.0; // Handle the case where emissionsFactor is not valid
      }

      return (distance / mileage) * emissionsFactor;
    }

    double calculateTotalReduction(double mileage, String selectedFuelType) {
      double totalReduction = 0.0;
      _weeklyData.forEach((date, data) {
        double walkingDistance = data['walking'] ?? 0.0;
        double cyclingDistance = data['cycling'] ?? 0.0;
        double reduction = footprintReduction(
          walkingDistance + cyclingDistance, // Total distance for the day
          walkingDistance, // Distance walked
          cyclingDistance, // Distance cycled
          mileage ?? 0.0, // Mileage (km/L) of the car
          selectedFuelType ?? 'Petrol', // Fuel type of the car
        );
        totalReduction += reduction;
      });
      return totalReduction;
    }

    void _storeTotalReduction(double totalReduction) async {
    await storage.writeTotalReduction(totalReduction);
    setState(() {
      _totalReduction = totalReduction;
    });
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Location and Step Tracker'),
        ),
        body: Column(
          children: [
            FuturisticCarbonFootprintCard(reductionAmount: _totalReduction.toStringAsFixed(3)),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_locationInfo),
                    SizedBox(height: 20),
                    Text(_stepCount),
                    SizedBox(height: 20),
                    Expanded(
                      child: DistanceChart(data: _weeklyData),
                    ),
                    SizedBox(height: 20), // Add spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  double calculateCarbonFootprint(double distance, double mileage, String fuelType) {
    // Check if distance, mileage, or emissionsFactor is Infinity or NaN
    if (distance.isInfinite || distance.isNaN || mileage.isInfinite || mileage.isNaN) {
      return 0.0; // Handle the case where inputs are not valid
    }

    double emissionsFactor = (fuelType == 'Petrol') ? 2.2 : 2.8;
    
    // Check if emissionsFactor is Infinity or NaN
    if (emissionsFactor.isInfinite || emissionsFactor.isNaN) {
      return 0.0; // Handle the case where emissionsFactor is not valid
    }

    return (distance / (mileage*1000)) * emissionsFactor;
  }

  double footprintReduction(
    double totalDistance,
    double walkingDistance,
    double cyclingDistance,
    double mileage,
    String carFuelType,
  ) {
    double reduction =calculateCarbonFootprint((walkingDistance + cyclingDistance), mileage, carFuelType);
    return reduction;
  }

  class FuturisticCarbonFootprintCard extends StatelessWidget {
    final String reductionAmount;

    FuturisticCarbonFootprintCard({required this.reductionAmount});

    @override
    Widget build(BuildContext context) {
      return Card(
        margin: EdgeInsets.all(16.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          width: 300,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco,
                size: 50.0,
                color: Colors.green,
              ),
              SizedBox(height: 16.0),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'You have reduced',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                '$reductionAmount kg',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                'of carbon emissions',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  class HomePage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: LocationTracker(),
      );
    }
  }
  /*
  void main() {
    runApp(HomePage());
  }
  */