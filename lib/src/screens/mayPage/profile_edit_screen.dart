import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    newUserName = widget.userName;
    newProfileImageUrl = widget.profileImageUrl;
    _userNameController.text = newUserName ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundImage: newProfileImageUrl != null && newProfileImageUrl!.isNotEmpty
                    ? (newProfileImageUrl!.startsWith('http')  // URLかローカルファイルかをチェック
                        ? NetworkImage(newProfileImageUrl!)
                        : File(newProfileImageUrl!).existsSync()  // ローカルファイルが存在するか
                          ? FileImage(File(newProfileImageUrl!))
                          : const AssetImage('assets/images/icon.png') as ImageProvider)
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
                }
                if (newProfileImageUrl != null) {
                  await _userService.saveProfileImageUrl(newProfileImageUrl!);
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text("保存"),
            ),
          ],
        ),
      ),
    );
  }
}