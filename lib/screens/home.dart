import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shibuya_app/env/env.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final List<LatLng> _polylineCoordinates = [];
  late BitmapDescriptor _customIcon;
  double _currentZoom = 14.0;

  Position? _currentPosition; // null許容型に変更
  final LatLng _shibuyaLatLng = const LatLng(35.658034, 139.701636); // 渋谷駅の座標

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCustomMarker();
  }

  /// 現在地を取得
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: _currentZoom,
          ),
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("現在地を取得できませんでした")));
    }
  }

  /// ルートを取得しPolylineを描画
  Future<void> _getRoute() async {
    if (_currentPosition == null) {
      // 現在地が取得できていない場合のエラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現在地が取得できていません")),
      );
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&destination=${_shibuyaLatLng.latitude},${_shibuyaLatLng.longitude}'
        '&key=${Env.key}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          final polylinePoints = PolylinePoints();
          final points = polylinePoints.decodePolyline(
              data['routes'][0]['overview_polyline']['points']);

          setState(() {
            _polylineCoordinates.clear();
            for (var point in points) {
              _polylineCoordinates
                  .add(LatLng(point.latitude, point.longitude));
            }
          });
        }
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {
      print("Error fetching directions: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("ルートを取得できませんでした")));
    }
  }

  /// カスタムマーカーをロード
  Future<void> _loadCustomMarker() async {
    // ignore: deprecated_member_use
    _customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/custom_marker.png',
    );
  }

  /// 地図のズームを更新
  void _zoomIn() {
    if (_currentZoom < 20) {
      setState(() {
        _currentZoom += 1;
        mapController.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
      });
    }
  }

  void _zoomOut() {
    if (_currentZoom > 5) {
      setState(() {
        _currentZoom -= 1;
        mapController.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shibuya Sightseeing Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _getRoute, // ルート案内ボタン
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(35.6585, 139.7013), // 渋谷の緯度経度
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              _getCurrentLocation();
            },
            markers: {
              Marker(
                markerId: const MarkerId('Shibuya'),
                position: _shibuyaLatLng,
                infoWindow: const InfoWindow(
                  title: '渋谷駅',
                  snippet: '目的地',
                ),
              ),
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('CurrentLocation'),
                  position:
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  infoWindow: const InfoWindow(
                    title: '現在地',
                  ),
                ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('Route'),
                color: Colors.blue,
                width: 5,
                points: _polylineCoordinates,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
        ],
      ),
    );
  }
}