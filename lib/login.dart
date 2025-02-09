import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'swipe.dart'; // Import your SwipeScreen

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

  // If user is already signed in, go to SwipeScreen
  void _checkUser() {
    if (_auth.currentUser != null) {
      _navigateToSwipeScreen();
    }
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled sign-in

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
        SnackBar(content: Text("Sign-In Failed")),
      );
    }
  }

  // Navigate to SwipeScreen after login
  void _navigateToSwipeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SwipeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Auth Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: _signInWithGoogle,
          child: Text("Sign in with Google"),
        ),
      ),
    );
  }
}
