import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shibuya_app/src/screens/language/global_language.dart';
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
    setState(() {});
  }

  Future<void> _takePicture() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const TakePictureScreen()),
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
        if (_image != null) {
          imageUrl = await StorageService.uploadImage(_image!);
        }
        final userName = await UserService().getUserName() ?? 'Unknown User';
        final userId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('posts').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'createdAt': FieldValue.serverTimestamp(),
          'userName': userName,
          'userId': userId,
          'likedBy': [],
          'likeCount': 0,
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿が成功しました！')),
        );
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
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

  // ここではプレビュー用の翻訳ボタンもそのまま残しています
  Future<void> _previewTranslation() async {
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) return;
    // 英語に翻訳する例
    final titleTranslation = await globalTranslator.translate(_titleController.text, to: 'en');
    final descriptionTranslation = await globalTranslator.translate(_descriptionController.text, to: 'en');
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('英語翻訳プレビュー'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('場所名: ${titleTranslation.text}'),
              const SizedBox(height: 8),
              Text('詳細情報: ${descriptionTranslation.text}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(text: '投稿', style: const TextStyle(fontSize: 20)),
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
                  labelText: null, // 下記でウィジェットとして表示
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '場所名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              // ラベルは TranslatedText で表示（選択言語に応じて翻訳）
              TranslatedText(text: '場所名', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '詳細情報を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              TranslatedText(text: '詳細情報', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              _image != null
                  ? Image.file(
                      _image!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                    )
                  : TranslatedText(
                      text: '写真が選択されていません',
                      style: const TextStyle(color: Colors.grey),
                    ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: TranslatedText(text: 'カメラで撮影'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectFromGallery,
                icon: const Icon(Icons.photo_library),
                label: TranslatedText(text: 'ギャラリーから選択'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePost,
                child: TranslatedText(text: '投稿する'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _previewTranslation,
                child: TranslatedText(text: '英語翻訳プレビュー'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}