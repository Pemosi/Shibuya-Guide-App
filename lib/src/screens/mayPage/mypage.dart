import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shibuya_app/src/screens/auth/login_or_registerPage.dart';
import 'package:shibuya_app/src/screens/favorite.dart';
import 'package:shibuya_app/src/screens/language/global_language.dart';
import 'package:shibuya_app/src/screens/mayPage/profile_edit_screen.dart';
import 'package:shibuya_app/service/user_service.dart';
import 'dart:io';
import 'package:shibuya_app/src/screens/mayPage/settings_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String userName = "ユーザー名";
  String? profileImageUrl;
  final TextEditingController _userNameController = TextEditingController();
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final storedUserName = await _userService.getUserName();
      final storedProfileImage = await _userService.getProfileImageUrl();
      if (mounted) {
        setState(() {
          userName = storedUserName ?? "ユーザー名";
          _userNameController.text = userName;
          profileImageUrl = storedProfileImage ?? ''; // null の場合は空文字
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final downloadUrl = await _userService.uploadProfileImage(imageFile);
    if (downloadUrl != null) {
      setState(() {
        profileImageUrl = downloadUrl; // 新しい画像URLをセット
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // AppBar のタイトルを TranslatedText でラップ
        title: TranslatedText(
          text: 'マイページ',
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    backgroundImage: (profileImageUrl == null || profileImageUrl!.isEmpty)
                        ? const AssetImage('assets/images/icon.png')
                        : NetworkImage(profileImageUrl!) as ImageProvider,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ユーザー名はそのまま表示（動的な内容なので翻訳不要）
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileEditScreen(
                                  userName: userName,
                                  profileImageUrl: profileImageUrl),
                            ),
                          );
                        },
                        // 「プロフィールを編集」も TranslatedText で表示
                        child: TranslatedText(
                          text: "プロフィールを編集",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildListTile('お気に入り', Icons.star, () {
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FavoritesScreen(
                            userId: currentUser!.uid,
                            onSelectSpot: (spot) {},
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: TranslatedText(
                            text: "ログインが必要です。",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }
                  }),
                  _buildListTile('いいね！履歴', Icons.thumb_up, () {}),
                  _buildListTile('ヘルプ', Icons.help, () {}),
                  _buildListTile('各種設定', Icons.settings, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  }),
                  _buildListTile('ログアウト', Icons.logout, () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginOrRegisterPage()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 32),
      // タイトルも TranslatedText で表示
      title: TranslatedText(
        text: title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}