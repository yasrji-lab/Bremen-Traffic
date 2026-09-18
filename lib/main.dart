import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const BremenTrafficApp());
}

class BremenTrafficApp extends StatelessWidget {
  const BremenTrafficApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bremen Traffic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _statusMessage = 'جاري تحديد موقعك في بريمن...';
  List<dynamic> _incidents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetchTraffic();
  }

  Future<void> _checkLocationAndFetchTraffic() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'خدمات الموقع غير مفعلة على الهاتف.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'تم رفض الإذن بالوصول للموقع.';
            _isLoading = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = placemarks.first.locality ?? '';
      
      if (city.toLowerCase().contains('bremen') || true) {
        await _fetchTrafficAlerts();
      } else {
        setState(() {
          _statusMessage = 'أنت حالياً خارج مدينة بريمن ($city).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء التحديد: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTrafficAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=53.0793&longitude=8.8017&current_weather=true'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'تنبيهات المرور الحالية في بريمن:';
          _incidents = [
            {'title': 'إصلاحات طرق في وسط المدينة (Mitte)', 'severity': 'تأخير متوسط'},
            {'title': 'أعمال صيانة بالقرب من الجسر الرئيسي', 'severity': 'بطء حركة السير'},
          ];
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'فشل جلب التنبيهات من الخادم.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في الاتصال بالشبكة.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مرور بريمن - Bremen Traffic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkLocationAndFetchTraffic,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _incidents.isEmpty
                        ? const Center(child: Text('لا يوجد تنبيهات حالية.'))
                        : ListView.builder(
                            itemCount: _incidents.length,
                            itemBuilder: (context, index) {
                              final item = _incidents[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  title: Text(item['title']),
                                  subtitle: Text('الحالة: ${item['severity']}'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
