import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'swipe.dart'; // Ensure you import your SwipeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is ready before async calls
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SwipeScreen(), // Ensure your SwipeScreen is correctly referenced
    );
  }
}
