import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shibuya_app/models/spots.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToFavorites(String userId, Spot spot) async {
    final favoritesRef = _firestore.collection('favorites').doc(userId);

    await favoritesRef.collection('userFavorites').doc(spot.placeId).set({
      'name': spot.name,
      'address': spot.address,
      'location': GeoPoint(spot.location.latitude, spot.location.longitude),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Spot>> getFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Spot(
                placeId: doc.id,
                name: data['name'],
                address: data['address'],
                location: LatLng(data['location'].latitude, data['location'].longitude),
                comment: "",
              );
            }).toList());
  }
}
