import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationTracker(),
    );
  }
}

class LocationTracker extends StatefulWidget {
  @override
  _LocationTrackerState createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  String _locationInfo = 'Location unavailable';
  Position? _previousPosition;

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  void _startTrackingLocation() async {
    try {
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
        Geolocator.getPositionStream().listen((Position updatedPosition) {
          if (_previousPosition == null ||
              Geolocator.distanceBetween(_previousPosition!.latitude, _previousPosition!.longitude, updatedPosition.latitude, updatedPosition.longitude) >= 10) {
            setState(() {
              _locationInfo = 'Latitude: ${updatedPosition.latitude}, Longitude: ${updatedPosition.longitude}';
              _previousPosition = updatedPosition;
            });
          }
        });
      }
    } catch (e) {
      // Handle the exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracker'),
      ),
      body: Center(
        child: Text(_locationInfo),
      ),
    );
  }
}
