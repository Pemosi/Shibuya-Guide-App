import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef = storageRef.child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = imagesRef.putFile(image);
      final snapshot = await uploadTask;

      // URL を取得
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('画像のアップロードに失敗しました: $e');
      throw Exception('画像のアップロードに失敗しました');
    }
  }
}