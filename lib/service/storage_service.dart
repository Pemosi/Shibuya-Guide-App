import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

class StorageService {
  static Future<String> uploadImage(File image) async {
    try {
      // 画像を読み込む
      img.Image? imageFile = img.decodeImage(image.readAsBytesSync());

      if (imageFile == null) {
        throw Exception("画像の読み込みに失敗しました");
      }

      // 圧縮（画像サイズを小さくする）
      img.Image compressedImage = img.copyResize(imageFile, width: 800); // 幅を800pxにリサイズ（必要に応じて調整）

      // 圧縮した画像をバイトデータに変換
      final compressedImageBytes = img.encodeJpg(compressedImage, quality: 85); // JPEG形式で圧縮

      // 圧縮された画像を一時ファイルとして保存
      final tempFile = File('${image.path}_compressed.jpg');
      await tempFile.writeAsBytes(compressedImageBytes);

      // Firebase Storageにアップロード
      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef = storageRef.child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = imagesRef.putFile(tempFile);

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