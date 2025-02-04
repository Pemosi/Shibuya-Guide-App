import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shibuya_app/src/screens/take_picture_screen.dart';
import 'package:shibuya_app/service/location_service.dart';
import 'package:shibuya_app/service/storage_service.dart';
import 'package:shibuya_app/service/user_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image; // 選択された画像
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    _currentPosition = await LocationService.getCurrentLocation(context);
    setState(() {}); // 画面更新
  }

  Future<void> _takePicture() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const TakePictureScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _image = result;
      });
    }
  }

  Future<void> _selectFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePost() async {
    if (_formKey.currentState!.validate() && _currentPosition != null) {
      try {
        String? imageUrl;

        // 画像が選択されている場合のみアップロード
        if (_image != null) {
          imageUrl = await StorageService.uploadImage(_image!);
        }

        // UserService を使用してユーザー名を取得
        final userName = await UserService().getUserName() ?? 'Unknown User';
        final userId = FirebaseAuth.instance.currentUser!.uid;

        // 投稿データを Firestore に保存
        await FirebaseFirestore.instance.collection('posts').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,  // 画像URLは画像が選択された場合のみ追加
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'createdAt': FieldValue.serverTimestamp(),
          'userName': userName, // ユーザー名を保存
          'userId': userId, // ユーザーIDも保存
          'likedBy': [],
          'likeCount': 0,
        });

        // 成功メッセージを表示
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿が成功しました！')),
        );

        // 入力フィールドと選択した画像をリセット
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
        print("Error: $e");
        // エラーメッセージを表示
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('場所情報または画像が正しく入力されていません')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '場所名',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // 角を丸くする
                    borderSide: BorderSide(color: Colors.blueAccent, width: 1.5), // 枠線の色と太さ
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0), // フォーカス時の枠線
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5), // 通常時の枠線
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0), // パディングを調整
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '場所名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '詳細情報',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '詳細情報を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _image != null
                ? Image.file(
                    _image!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.contain,
                  )
                : const Text(
                    '写真が選択されていません',
                    style: TextStyle(color: Colors.grey),
                  ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('カメラで撮影'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('ギャラリーから選択'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePost,
                child: const Text('投稿する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}