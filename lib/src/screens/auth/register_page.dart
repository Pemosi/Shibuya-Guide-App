import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shibuya_app/components/my_buttom.dart';
import 'package:shibuya_app/components/my_textfield.dart';
import 'package:shibuya_app/components/square_tile.dart';
import 'package:shibuya_app/routes.dart';
import 'package:shibuya_app/service/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUserUp() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // check if both password and confirm password is same
      if (passwordController.text == confirmPasswordController.text) {
        // Firebaseでユーザー登録
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context); // ローディングインジケーターを閉じる

        // PostViewPageに遷移
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => RoutePage(),
          ),
        );
      } else {
        // パスワード不一致エラー
        genericErrorMessage("パスワードが一致しませんでした。再度お試しください。");
      }
    } on FirebaseAuthException catch (e) {
      // ローディングインジケーターを閉じる
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // Firebaseのエラーメッセージを表示
      genericErrorMessage(e.message ?? "エラーが発生しました。");
    }
  }

  void genericErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 243),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 25),

                // メールアドレス入力
                MyTextField(
                  controller: emailController,
                  hintText: 'メールアドレス',
                  obscureText: false,
                ),
                const SizedBox(height: 15),

                // パスワード入力
                MyTextField(
                  controller: passwordController,
                  hintText: 'パスワード',
                  obscureText: true,
                ),
                const SizedBox(height: 15),

                // 確認用パスワード入力
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: '確認用パスワード',
                  obscureText: true,
                ),
                const SizedBox(height: 15),

                // 登録ボタン
                MyButton(
                  onTap: signUserUp,
                  text: 'アカウントを登録',
                ),
                const SizedBox(height: 20),

                // continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                //google + apple button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //google buttom
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(context),
                      imagePath: 'lib/icons/google.png',
                      height: 70,
                    ),

                    SizedBox(width: 20),
                    // apple buttom
                    SquareTile(
                      onTap: () {},
                      imagePath: 'lib/icons/apple.png',
                      height: 70,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                ),

                // ログインリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'すでにアカウントをお持ちですか？',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    TextButton(
                      onPressed: widget.onTap,
                      child: Text(
                        '今すぐログイン',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}