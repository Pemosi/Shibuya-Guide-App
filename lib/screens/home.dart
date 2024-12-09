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
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  late BitmapDescriptor _customIcon;
  double _currentZoom = 14.0; // 初期ズームレベル

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation(); // 初期位置はonMapCreatedで取得するように変更
    // _loadCustomMarker();
  }

  /// 現在地を取得してカメラを移動
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
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
    }
  }

  /// カスタムマーカーをロード
  // Future<void> _loadCustomMarker() async {
  //   // ignore: deprecated_member_use
  //   _customIcon = await BitmapDescriptor.fromAssetImage(
  //     const ImageConfiguration(size: Size(48, 48)),
  //     'assets/custom_marker.png', // カスタムアイコンのパス
  //   );
  // }

  /// マーカーを追加
  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          icon: _customIcon,
          infoWindow: InfoWindow(
            title: 'カスタムマーカー',
            snippet: '緯度: ${position.latitude}, 経度: ${position.longitude}',
          ),
        ),
      );
    });
  }

  /// 地図のズームを更新
  void _zoomIn() {
    setState(() {
      _currentZoom += 1; // ズームイン
      mapController.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1; // ズームアウト
      mapController.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
    });
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
              // 地図作成後に現在地を取得
              _getCurrentLocation();
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onLongPress: _addMarker,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add), // 拡大ボタン
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove), // 縮小ボタン
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}