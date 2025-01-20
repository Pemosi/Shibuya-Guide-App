import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}