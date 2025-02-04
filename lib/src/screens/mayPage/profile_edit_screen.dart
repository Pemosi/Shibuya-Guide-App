import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shibuya_app/service/user_service.dart';
import 'dart:io';

class ProfileEditScreen extends StatefulWidget {
  final String userName;
  final String? profileImageUrl;

  const ProfileEditScreen({super.key, required this.userName, this.profileImageUrl});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String? newUserName;
  String? newProfileImageUrl;
  final TextEditingController _userNameController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false; // ローディング中かどうか

  @override
  void initState() {
    super.initState();
    newUserName = widget.userName;
    newProfileImageUrl = widget.profileImageUrl;
    _userNameController.text = newUserName ?? '';
  }

  // 画像を選択するメソッド
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true; // 画像アップロード中
    });

    // 画像ファイルを取得
    File imageFile = File(pickedFile.path);

    // Firebaseの現在のユーザーを取得
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ユーザーサービスで画像をアップロード
    final downloadUrl = await _userService.uploadProfileImage(imageFile);
    if (downloadUrl != null) {
      setState(() {
        newProfileImageUrl = downloadUrl;  // 画像URLを更新
        _isLoading = false; // ローディング終了
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage, // アイコンをタップしたときに画像選択を呼び出す
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                backgroundImage: _isLoading
                    ? const AssetImage('assets/images/loading.gif') // ローディング中の画像
                    : newProfileImageUrl != null && newProfileImageUrl!.isNotEmpty
                        ? NetworkImage(newProfileImageUrl!)
                        : const AssetImage('assets/images/icon.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userNameController,
              maxLength: 15,
              decoration: const InputDecoration(labelText: 'ユーザー名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final updatedUserName = _userNameController.text;
                if (updatedUserName.isNotEmpty) {
                  await _userService.saveUserName(updatedUserName);
                  setState(() {
                    newUserName = updatedUserName; // ユーザー名を更新
                  });
                }
                if (newProfileImageUrl != null) {
                  await _userService.saveProfileImageUrl(newProfileImageUrl!);
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text("保存"),
            ),
            const SizedBox(height: 16),
            // ユーザー名と画像のリアルタイム表示
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final userData = snapshot.data!;
                  final userName = userData['userName'] ?? '';
                  final profileImageUrl = userData['profileImageUrl'] ?? '';

                  return Column(
                    children: [
                      Text('現在のユーザー名: $userName'),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage('assets/images/icon.png') as ImageProvider,
                      ),
                    ],
                  );
                }
                return const Text('データ取得エラー');
              },
            ),
          ],
        ),
      ),
    );
  }
}