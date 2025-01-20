import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:shibuya_app/routes.dart';

class AuthService {
  // Google sign in
  Future<User?> signInWithGoogle(BuildContext context) async {
    // begin interactive sign in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    // obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    // create new credentials for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // sign in!
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Check if user is successfully signed in
    if (userCredential.user != null) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return RoutePage();
          },
        ),
      );
    }

    return userCredential.user;
  }
}