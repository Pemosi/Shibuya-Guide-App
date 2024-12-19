import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController; // null許容型に変更
  Position? _currentPosition;
  final double _currentZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 現在地を取得
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('位置情報サービスが無効です。');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('位置情報のアクセス許可が拒否されました。');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('位置情報のアクセス許可が永久に拒否されています。');
      }

      final position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // mapControllerが初期化済みの場合のみカメラを移動
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: _currentZoom,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現在地を取得できませんでした")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('現在地マップ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: _currentZoom,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller; // マップコントローラーを初期化
              },
              markers: {
                const Marker(
                  markerId: MarkerId('Sydney'),
                )
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
    );
  }
}