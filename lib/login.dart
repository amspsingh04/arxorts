import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'swipe.dart'; 

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() {
    if (_auth.currentUser != null) {
      _navigateToSwipeScreen();
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      _navigateToSwipeScreen();
    } catch (e) {
      print("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-In Failed")),
      );
    }
  }

  // Navigate to SwipeScreen after login
  void _navigateToSwipeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SwipeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Auth Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: _signInWithGoogle,
          child: const Text("Sign in with Google"),
        ),
      ),
    );
  }
}
