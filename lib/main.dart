import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shibuya_app/env/env.dart';
import 'package:shibuya_app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  const platform = MethodChannel('com.example.shibuyaapp/api');
  platform.invokeMethod('setApiKey', Env.key);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '渋谷観光ガイドアプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RoutePage(),
    );
  }
}