// lib/models/spots.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Spot {
  final String placeId;
  final String name;
  final String address;
  final GeoPoint location;
  final String comment;

  Spot({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    required this.comment,
  });
}