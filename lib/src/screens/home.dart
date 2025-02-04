import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:shibuya_app/env/env.dart';
import 'package:shibuya_app/models/place_repository.dart';
import 'package:shibuya_app/models/spots.dart';
import 'package:exif/exif.dart';
import 'dart:io';
import 'package:shibuya_app/service/firestore_service.dart';
import 'package:shibuya_app/src/screens/language/global_language.dart';

class HomeScreen extends StatefulWidget {
  final File? photo;
  const HomeScreen({super.key, this.photo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _initialPosition = const LatLng(35.6586, 139.7454);
  GoogleMapController? mapController;
  final TextEditingController _searchController = TextEditingController();
  Spot? selectedSpot;
  String? selectedPhotoUrl;
  List<Map<String, dynamic>> searchedValue = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  final PlaceRepository placeRepository = PlaceRepository();

  // 検索結果をクリアするメソッド
  void _resetResult() {
    setState(() {
      selectedSpot = null;
      selectedPhotoUrl = null;
      searchedValue = [];
      markers = {};
      polylines.clear();
    });
  }

  // 現在位置を取得するメソッド
  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 現在地取得
    if (widget.photo != null) {
      _displayRouteFromPhoto(widget.photo!);
    }
  }

  Future<void> _displayRouteFromPhoto(File photo) async {
    final LatLng? destination = await _getLatLngFromPhoto(photo);

    if (destination == null) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const TranslatedText(text: "位置情報が見つかりません"),
          content: const TranslatedText(text: "この写真には位置情報が含まれていません。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const TranslatedText(text: "OK"),
            ),
          ],
        ),
      );
      return;
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    markers.clear();
    markers.add(Marker(markerId: const MarkerId('current'), position: currentLatLng));
    markers.add(Marker(markerId: const MarkerId('destination'), position: destination));

    await _drawRoute(currentLatLng, destination);
  }

  Future<void> displayRouteFromPhoto(File photo) async {
    final LatLng? destination = await _getLatLngFromPhoto(photo);

    if (destination == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const TranslatedText(text: "位置情報が見つかりません"),
          content: const TranslatedText(text: "この写真には位置情報が含まれていません。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const TranslatedText(text: "OK"),
            ),
          ],
        ),
      );
      return;
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    markers.clear();
    markers.add(Marker(markerId: const MarkerId('current'), position: currentLatLng));
    markers.add(Marker(markerId: const MarkerId('destination'), position: destination));

    await _drawRoute(currentLatLng, destination);
  }

  Future<LatLng?> _getLatLngFromPhoto(File photo) async {
    final bytes = await photo.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    if (tags.containsKey('GPS GPSLatitude') && tags.containsKey('GPS GPSLongitude')) {
      final latitude = tags['GPS GPSLatitude']!.printable;
      final longitude = tags['GPS GPSLongitude']!.printable;
      return LatLng(_convertToDecimal(latitude), _convertToDecimal(longitude));
    }
    return null;
  }

  double _convertToDecimal(String dms) {
    final parts = dms.split(',').map((e) => e.trim()).toList();
    if (parts.length == 3) {
      final degrees = double.parse(parts[0]);
      final minutes = double.parse(parts[1]) / 60;
      final seconds = double.parse(parts[2]) / 3600;
      return degrees + minutes + seconds;
    }
    return 0.0;
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        Env.key,
        PointLatLng(origin.latitude, origin.longitude),
        PointLatLng(destination.latitude, destination.longitude),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });

        LatLngBounds bounds;
        if (origin.latitude > destination.latitude) {
          bounds = LatLngBounds(
            southwest: destination,
            northeast: origin,
          );
        } else {
          bounds = LatLngBounds(
            southwest: origin,
            northeast: destination,
          );
        }

        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      print("ルート取得中にエラーが発生しました: $e");
    }
  }

  // 入力文字列による検索結果を取得
  void _searchPossiblePlacesList(String string) async {
    print("検索文字列: $string");

    List<Map<String, dynamic>> result = [];
    PlacesAutocompleteResponse placesAutocompleteResponse =
        await placeRepository.getAutocomplete(string);

    print("PlacesAutocompleteResponse: ${placesAutocompleteResponse.toJson()}");

    if (placesAutocompleteResponse.predictions.isNotEmpty) {
      print("予測候補: ${placesAutocompleteResponse.predictions}");

      for (var prediction in placesAutocompleteResponse.predictions) {
        if (prediction.placeId != null) {
          result.add({
            "placeId": prediction.placeId!,
            "description": prediction.description,
          });
          print("placeId: ${result}");
        }
      }

      setState(() {
        searchedValue = result;
      });
    } else {
      print("予測候補が見つかりませんでした");
    }
  }

  // リストタップ時の処理
  void _onTapList(int index) async {
    final placeId = searchedValue[index]["placeId"];
    PlacesDetailsResponse placesDetailsResponse =
        await placeRepository.getPlaceDetails(placeId);

    String name = placesDetailsResponse.result.name;
    String address = placesDetailsResponse.result.formattedAddress!;
    Location location = placesDetailsResponse.result.geometry!.location;

    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId(placeId),
          icon: BitmapDescriptor.defaultMarkerWithHue(350),
          position: LatLng(location.lat, location.lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
          ),
        ),
      );

      selectedSpot = Spot(
        placeId: placeId,
        name: name,
        address: address,
        location: LatLng(location.lat, location.lng),
        comment: "",
      );

      if (placesDetailsResponse.result.photos.isNotEmpty) {
        selectedPhotoUrl = placeRepository.buildPhotoUrl(
          photoReference: placesDetailsResponse.result.photos[0].photoReference,
          maxHeight: 300,
        );
      } else {
        selectedPhotoUrl = null;
      }

      searchedValue = [];
    });

    Position currentPosition = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    await _drawRoute(currentLatLng, LatLng(location.lat, location.lng));

    // ボトムシート表示
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      Scaffold.of(context).showBottomSheet(
        (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(
                  text: name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TranslatedText(text: address, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                if (selectedPhotoUrl != null)
                  Image.network(
                    selectedPhotoUrl!,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final FirestoreService firestoreService = FirestoreService();
                    final auth = FirebaseAuth.instance;
                    final userId = auth.currentUser?.uid.toString();

                    await firestoreService.addToFavorites(userId!, selectedSpot!);

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: TranslatedText(text: '${selectedSpot?.name} がお気に入りに追加されました')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const TranslatedText(text: 'お気に入り登録する'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.white,
      );
    }
  }

  // 検索入力欄
  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 40,
      child: TextFormField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _resetResult();
                },
              ),
            ],
          ),
          hintText: '検索',
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(128),
          ),
        ),
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (value) {
          _searchPossiblePlacesList(value);
        },
        onChanged: (inputString) {
          if (inputString.isEmpty) {
            _resetResult();
          }
        },
      ),
    );
  }

  // 検索候補リスト
  Widget _buildSuggestionList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: searchedValue.length,
      itemBuilder: (context, index) {
        final suggestion = searchedValue[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          child: ListTile(
            title: Text(
              suggestion['description'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              "候補をタップして選択してください",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () => _onTapList(index),
          ),
        );
      },
    );
  }

  // 地図ウィジェット
  Widget _buildMap() {
    return GoogleMap(
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 10,
      ),
      markers: markers,
      polylines: polylines,
      onMapCreated: (tempMapController) {
        mapController = tempMapController;
        if (markers.isNotEmpty) {
          setState(() {});
        }
      },
    );
  }

  // 現在地ボタン
  Widget _goToCurrentPositionButon() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(55, 55),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
      ),
      onPressed: () async {
        Position currentPosition = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high,
        );
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currentPosition.latitude,
                currentPosition.longitude,
              ),
              zoom: 14,
            ),
          ),
        );
      },
      child: const Icon(Icons.near_me_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            right: 10,
            bottom: 70,
            child: _goToCurrentPositionButon(),
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Stack(
                children: <Widget>[
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      _buildInput(),
                      if (searchedValue.isNotEmpty) _buildSuggestionList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}