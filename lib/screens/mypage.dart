import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shibuya_app/models/spots.dart';
import 'package:shibuya_app/screens/favorite.dart';
import 'package:shibuya_app/screens/login_page.dart';
import 'package:shibuya_app/service/user_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String userName = "ユーザー名"; // 現在のユーザー名
  final int ticketCount = 5;
  final int likesLeft = 100;

  final TextEditingController _userNameController = TextEditingController();
  bool _isEditing = false;

  final UserService _userService = UserService(); // UserServiceインスタンス

  @override
  void initState() {
    super.initState();
    _loadUserName(); // ユーザー名をFirestoreからロード
  }

  Future<void> _loadUserName() async {
    final storedUserName = await _userService.getUserName();
    if (mounted) {
      setState(() {
        userName = storedUserName ?? "ユーザー名"; // データがなければデフォルトに設定
        _userNameController.text = userName; // コントローラーにも設定
      });
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'マイページ',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _isEditing
                                  ? TextField(
                                      controller: _userNameController,
                                      maxLength: 15,
                                      decoration: const InputDecoration(
                                        labelText: 'ユーザー名',
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    )
                                  : Text(
                                      userName,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            // 編集中かどうかで表示を変更
                            _isEditing
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.save,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        // 編集終了時、Firestoreに保存
                                        userName = _userNameController.text;
                                        _userService.saveUserName(userName);
                                        _isEditing = false; // 保存後に編集を終了
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = !_isEditing; // 編集モードに切り替え
                                      });
                                    },
                                  ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildListTile('お知らせ', Icons.notifications, 3),
                    _buildListTile(
                      'お気に入り', Icons.star, 0,
                      onTap: () {
                        if (currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoritesScreen(
                                userId: currentUser.uid,
                                onSelectSpot: (spot) {
                                  // Google Maps で開く処理
                                  launchGoogleMaps(spot);
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("ログインが必要です。"))
                          );
                        }
                      },
                    ),
                    _buildListTile('いいね！履歴', Icons.thumb_up, 0),
                    _buildListTile('安心・安全ガイド', Icons.security, 0),
                    _buildListTile('ヘルプ', Icons.help, 0),
                    _buildListTile('各種設定', Icons.settings, 1),
                    _buildListTile(
                      'ログアウト', Icons.logout, 0,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage(onTap: () {},)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, int notificationCount, {VoidCallback? onTap}) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, size: 32),
          if (notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  notificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void launchGoogleMaps(Spot spot) {
    final url = 'https://www.google.com/maps/search/?api=1&query=${spot.location.latitude},${spot.location.longitude}';
    launchUrl(Uri.parse(url));
  }
}