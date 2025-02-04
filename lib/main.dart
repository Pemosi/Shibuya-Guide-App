// import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shibuya_app/env/env.dart';
import 'package:shibuya_app/firebase_options.dart';
import 'package:shibuya_app/src/screens/auth/login_or_registerPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // final cameras = await availableCameras();
  // final firstCamera = cameras.first;
  const platform = MethodChannel('com.example.shibuyaapp/api');
  platform.invokeMethod('setApiKey', Env.key);
  // runApp(MyApp(camera: firstCamera))
  //; カメラ機能を確認するときにこのコメントアウト等を消してください
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    //required this.camera,
  });

  // final CameraDescription? camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '渋谷観光ガイドアプリ',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginOrRegisterPage(),
    );
  }
}