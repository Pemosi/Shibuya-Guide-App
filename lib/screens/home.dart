import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shibuya_app/models/place_repository.dart';
import 'package:shibuya_app/models/spots.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _initialPosition = LatLng(35.6586, 139.7454);
  GoogleMapController? mapController;

  Spot? selectedSpot;
  String? selectedPhotoUrl;
  List<Map<String, dynamic>> searchedValue = [];
  Set<Marker> markers = {};

  final PlaceRepository placeRepository = PlaceRepository();

  // 取得結果をクリアする
  void _resetResult() {
    setState(() {
      selectedSpot = null;
      selectedPhotoUrl = null;
      searchedValue = [];
      markers = {};
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
  }

  // 入力文字列による検索結果をGoogleMapApiから取得する
  void _searchPossiblePlacesList(String string) async {
    print("検索文字列: $string");

    List<Map<String, dynamic>> result = [];
    PlacesAutocompleteResponse placesAutocompleteResponse =
        await placeRepository.getAutocomplete(string);

    // placesAutocompleteResponse の内容を確認する
    print("PlacesAutocompleteResponse: ${placesAutocompleteResponse.toJson()}");

    // 予測候補が存在する場合のみ処理を行う
    if (placesAutocompleteResponse.predictions.isNotEmpty) {
      print("予測候補: ${placesAutocompleteResponse.predictions}");

      for (var prediction in placesAutocompleteResponse.predictions) {
        result.add({"placeId": prediction.placeId, "description": prediction.description});
        print("placeId？に入ってくる値$result");
      }

      setState(() {
        searchedValue = result;
      });
    } else {
      print("予測候補が見つかりませんでした");
    }
  }

  // リストをタップされたら、placeIdから詳細情報を取ってくる
  void _onTapList(int index) async {
    final placeId = searchedValue[index]["placeId"];
    // 上記で取得した情報から詳細情報（緯度経度など）を取得
    PlacesDetailsResponse placesDetailsResponse =
        await placeRepository.getPlaceDetails(placeId);

    String name = placesDetailsResponse.result.name;
    String address = placesDetailsResponse.result.formattedAddress!;
    Location location = placesDetailsResponse.result.geometry!.location;

    // googleMap上にMarkerを設置するように、値を更新する
    setState(() {
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
        location: GeoPoint(location.lat, location.lng),
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
    });

    // mapの中心を、選択したスポットの位置にする。
    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.lat, location.lng),
          zoom: 16,
        ),
      ),
    );

    // markerの上のwindowを開く
    if (markers.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 200));  // 少し遅延を入れてから
      await mapController!.showMarkerInfoWindow(MarkerId(placeId));
    }
  }

  // 検索欄
  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 40,
      child: TextFormField(
        autofocus: true,
        style: TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: '場所名/住所で検索',
        ),
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (value) {
          // 検索ボタンを押したら検索を実行する
          _searchPossiblePlacesList(value);
        },
        onChanged: (inputString) {
          // 一度検索したのちに再度文字列を変更したら、一旦情報をリセットする
          if (inputString.isEmpty) {
            _resetResult();  // 入力が空になった場合にリセット
          }
        },
      ),
    );
  }

  // 検索結果の一覧
  Widget _resultList() {
    return searchedValue.isEmpty
        ? Container()
        : Container(
            height: 150,
            padding: EdgeInsets.fromLTRB(5, 0, 5, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchedValue.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    _onTapList(index);
                  },
                  child: Card(
                    // 選択しているものとそうでないもので背景色を変える
                    color: selectedSpot != null
                        ? searchedValue[index]["placeId"] == selectedSpot!.placeId
                            ? Colors.white
                            : Colors.grey[200]
                        : Colors.grey[200],
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 1, 20, 1),
                      child: Text(searchedValue[index]["description"]),
                    ),
                  ),
                );
              },
            ),
          );
  }

  // 地図
  Widget _buildMap() {
    return GoogleMap(
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 10,
      ),
      markers: markers,
      onMapCreated: (tempMapController) {
        mapController = tempMapController;
        if (markers.isNotEmpty) {
          setState(() {});  // マーカーがあれば更新する
        }
      },
    );
  }

  //　現在地ボタン処理
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
              target:LatLng(
                currentPosition.latitude,
                currentPosition.longitude
              ),
              zoom: 14,
            ),
          ),
        );
      },
      child: const Icon(Icons.near_me_outlined),
    );
  }

  Widget _buildSpotImage() {
    if (selectedPhotoUrl == null) {
      return Container();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(2)),
      child: Image.network(selectedPhotoUrl!, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('場所検索'),
      ),
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
              margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Stack(
                children: <Widget>[
                  // 画像だけ下に配置する
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildSpotImage(),
                  ),
                  // 検索フォームと結果は上側に順番に表示する
                  Column(
                    children: [
                      _buildInput(),
                      _resultList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: selectedSpot == null
          ? Container()
          : FloatingActionButton.extended(
              onPressed: () {
                // 登録機能などを追加する場合はここに処理を書く
              },
              label: Row(
                children: [
                  Icon(Icons.create_outlined),
                  Text("登録する"),
                ],
              ),
            ),
    );
  }
}