import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ユーザー名を保存する
  Future<void> saveUserName(String userName) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(userId).set({
      'userName': userName,
    }, SetOptions(merge: true)); // 既存のデータにマージ
  }

  // ユーザー名を取得する
  Future<String?> getUserName() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['userName'];
    }
    return null; // データがなければnull
  }

  // プロフィール画像をアップロードする
  Future<String?> uploadProfileImage(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = _storage.ref().child('profile_images/$userId.jpg');

    try {
      // 画像を読み込み、圧縮する
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image == null) return null;

      // 圧縮（例：幅600pxに縮小）
      img.Image resizedImage = img.copyResize(image, width: 600);  // サイズを600pxに圧縮

      // 圧縮後の画像をバイトデータに変換
      final compressedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

      // Firebase Storageにアップロード
      await ref.putData(compressedImageBytes);
      final downloadUrl = await ref.getDownloadURL();

      // FirestoreにダウンロードURLを保存
      await _firestore.collection('users').doc(userId).set({
        'profileImageUrl': downloadUrl,
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }

  // プロフィール画像URLを取得する
  Future<String?> getProfileImageUrl() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['profileImageUrl'];
    }
    return null;
  }

  Future<void> saveProfileImageUrl(String profileImageUrl) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('users').doc(userId).set({
      'profileImageUrl': profileImageUrl,
    }, SetOptions(merge: true));
  }
}