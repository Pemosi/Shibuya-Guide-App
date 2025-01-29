import 'package:flutter/material.dart';
import 'package:shibuya_app/models/spots.dart';
import 'package:shibuya_app/service/firestore_service.dart';

class FavoritesScreen extends StatelessWidget {
  final Function(Spot) onSelectSpot;
  final String userId;

  const FavoritesScreen({super.key, required this.onSelectSpot, required this.userId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text("お気に入り")),
      body: StreamBuilder<List<Spot>>(
        stream: firestoreService.getFavorites(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final spots = snapshot.data!;

          return ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return ListTile(
                title: Text(spot.name),
                subtitle: Text(spot.address),
                trailing: ElevatedButton(
                  onPressed: () {
                    onSelectSpot(spot);
                    Navigator.pop(context); // ホームに戻る
                  },
                  child: Text("Google Mapで表示"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}