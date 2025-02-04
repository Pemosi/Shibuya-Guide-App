// import 'package:flutter/material.dart';
// import 'package:shibuya_app/models/spots.dart';
// import 'package:shibuya_app/service/firestore_service.dart';

// class SpotCard extends StatelessWidget {
//   final Spot spot;
//   final String userId; // FirebaseAuthで取得する予定

//   const SpotCard({super.key, required this.spot, required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     final FirestoreService firestoreService = FirestoreService();

//     return Card(
//       child: ListTile(
//         title: Text(spot.name),
//         subtitle: Text(spot.address),
//         trailing: IconButton(
//           icon: Icon(Icons.favorite_border),
//           onPressed: () {
//             firestoreService.addToFavorites(userId, spot);
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('${spot.name} をお気に入りに追加しました！')),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
