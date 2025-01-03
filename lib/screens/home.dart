import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:shibuya_app/env/env.dart';

class HomeScreen extends StatefulWidget {
  final double? destinationLatitude; // 目的地の緯度
  final double? destinationLongitude; // 目的地の経度

  const HomeScreen({
    super.key,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final double _currentZoom = 14.0;
  GooglePlace? googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    googlePlace = GooglePlace(Env.key); // 環境変数からAPIキーを取得
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
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現在地を取得できませんでした")),
      );
    }
  }

  /// 検索処理
  void autoCompleteSearch(String value) async {
    final result = await googlePlace?.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('現在地マップ'),
      ),
      body: Stack(
        children: [
          _currentPosition == null
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
                    _mapController = controller;
                  },
                  markers: _createMarkers(),
                  polylines: _createPolylines(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "btn2",
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextField(
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      autoCompleteSearch(value);
                                    } else {
                                      setState(() {
                                        predictions = [];
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '場所を検索',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: predictions.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        predictions[index].description ?? '',
                                      ),
                                      onTap: () async {
                                        final placeId = predictions[index].placeId;
                                        if (placeId != null) {
                                          final details = await googlePlace?.details.get(placeId);
                                          if (details != null && details.result != null) {
                                            final location = details.result!.geometry!.location;
                                            if (location != null) {
                                              setState(() {
                                                _mapController?.animateCamera(
                                                  CameraUpdate.newLatLng(
                                                    LatLng(location.lat, location.lng),
                                                  ),
                                                );
                                                predictions = [];
                                              });
                                              Navigator.pop(context);
                                            }
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 現在地と目的地のマーカーを作成
  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: '現在地'),
        ),
      );
    }

    if (widget.destinationLatitude != null &&
        widget.destinationLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            widget.destinationLatitude!,
            widget.destinationLongitude!,
          ),
          infoWindow: const InfoWindow(title: '目的地'),
        ),
      );
    }

    return markers;
  }

  /// 現在地から目的地へのポリラインを作成
  Set<Polyline> _createPolylines() {
    if (_currentPosition == null ||
        widget.destinationLatitude == null ||
        widget.destinationLongitude == null) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          LatLng(
            widget.destinationLatitude!,
            widget.destinationLongitude!,
          ),
        ],
        color: Colors.blue,
        width: 5,
      ),
    };
  }
}