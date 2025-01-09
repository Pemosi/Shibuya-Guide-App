import 'package:google_maps_webservice/places.dart';
import 'package:shibuya_app/env/env.dart';

class PlaceRepository {
  final placesApiClient = GoogleMapsPlaces(apiKey: Env.key);

  // 文字列による場所検索
  Future<PlacesAutocompleteResponse> getAutocomplete(String input) async {
    return await placesApiClient.autocomplete(input, language: 'ja');
  }

  // 詳細情報を取得
  Future<PlacesDetailsResponse> getPlaceDetails(String placeId) async {
    return await placesApiClient.getDetailsByPlaceId(placeId);
  }

  // 写真のURLを生成するメソッドを追加
  String buildPhotoUrl({required String photoReference, required int maxHeight}) {
    return "https://maps.googleapis.com/maps/api/place/photo?maxheight=$maxHeight&photo_reference=$photoReference&key=${Env.key}";
  }
}