import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shibuya_app/screens/home.dart';
import 'package:shibuya_app/screens/take_picture_screen.dart';
import 'package:shibuya_app/service/location_service.dart';
import 'package:shibuya_app/service/storage_service.dart';

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

  Future<void> _savePost() async {
    if (_formKey.currentState!.validate() && _currentPosition != null) {
      try {
        String? imageUrl;

        if (_image != null) {
          imageUrl = await StorageService.uploadImage(_image!);
        }

        await FirebaseFirestore.instance.collection('posts').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'createdAt': FieldValue.serverTimestamp(),
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
                decoration: const InputDecoration(
                  labelText: '場所名',
                  hintText: '例: 渋谷スクランブル交差点',
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
                decoration: const InputDecoration(
                  labelText: '詳細情報',
                  hintText: '場所についての詳細情報',
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
                      height: 200,
                      fit: BoxFit.cover,
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
              ElevatedButton(
                onPressed: _savePost,
                child: const Text('投稿する'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_currentPosition != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          // destinationLatitude: _currentPosition!.latitude,
                          // destinationLongitude: _currentPosition!.longitude,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('現在地が取得されていません')),
                    );
                  }
                },
                child: const Text('この場所にいく'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}