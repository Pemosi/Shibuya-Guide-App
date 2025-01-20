import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shibuya_app/routes.dart';
import 'login_or_registerPage.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user logged in
          if(snapshot.hasData){
            return RoutePage();
          }
          //user not logged in
          else{
            return LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}