import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  void signInWithGoogle(BuildContext context) async {
    try {
      // Google認証フローを起動する
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした場合
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サインインがキャンセルされました')),
        );
        return;
      }

      // リクエストから認証情報を取得する
      final googleAuth = await googleUser.authentication;

      // FirebaseAuthで認証を行うため、credentialを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 作成したcredentialを元にFirebaseAuthで認証を行う
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo!.isNewUser) {
        // 新規ユーザーの場合の処理
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新規ユーザーとしてサインインしました')),
        );
      } else {
        // 既存ユーザーの場合の処理
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('既存ユーザーとしてサインインしました')),
        );
      }
    } on FirebaseException catch (e) {
      // Firebase関連のエラー
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebaseエラー: ${e.message}')),
      );
    } catch (e) {
      // その他のエラー
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('サインイン中にエラーが発生しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Googleサインイン'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => signInWithGoogle(context),
          child: const Text('Googleでサインイン'),
        ),
      ),
    );
  }
}
