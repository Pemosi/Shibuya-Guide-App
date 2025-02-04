import 'package:google_maps_flutter/google_maps_flutter.dart';

class Spot {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final String comment;

  Spot({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    required this.comment,
  });
}