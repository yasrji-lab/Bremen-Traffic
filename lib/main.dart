import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تنبيهات بريمن',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const TrafficAlertScreen(),
    );
  }
}

class TrafficAlertScreen extends StatefulWidget {
  const TrafficAlertScreen({super.key});

  @override
  State<TrafficAlertScreen> createState() => _TrafficAlertScreenState();
}

class _TrafficAlertScreenState extends State<TrafficAlertScreen> {
  bool isTracking = false;
  String statusMessage = "التتبع متوقف";

  final String serverUrl = "https://bremen-traffic-incidents-1--yasrjiahmed.repl.co/check-incidents";

  Future<void> toggleTracking(bool value) async {
    setState(() {
      isTracking = value;
      statusMessage = isTracking ? "التتبع يعمل في الخلفية..." : "التتبع متوقف";
    });

    if (isTracking) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        checkCurrentLocationAndAlert();
      } else {
        setState(() {
          isTracking = false;
          statusMessage = "تم رفض إذن الوصول للموقع";
        });
      }
    }
  }

  Future<void> checkCurrentLocationAndAlert() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String currentStreet = placemarks.first.thoroughfare ?? "Bremen";

      var response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'current_street': currentStreet}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['alert'] == true) {
          setState(() {
            statusMessage = "⚠️ ${data['message']}";
          });
        }
      }
    } catch (e) {
      print("خطأ في فحص الموقع: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبيهات بريمن المرورية'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTracking ? Icons.radar : Icons.radar_outlined,
                size: 100,
                color: isTracking ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SwitchListTile(
                title: const Text('تفعيل التنبيهات المباشرة', style: TextStyle(fontSize: 18)),
                value: isTracking,
                onChanged: toggleTracking,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
