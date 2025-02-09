import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pdf.dart';

class SavedArticlesScreen extends StatefulWidget {
  @override
  _SavedArticlesScreenState createState() => _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends State<SavedArticlesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> savedArticles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSavedArticles();
  }

  Future<void> fetchSavedArticles() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_articles')
          .get();

      setState(() {
        savedArticles = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching saved articles: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Articles")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedArticles.isEmpty
              ? const Center(child: Text("No saved articles!"))
              : ListView.builder(
                  itemCount: savedArticles.length,
                  itemBuilder: (context, index) {
                    final article = savedArticles[index];
                    return ListTile(
                      title: Text(article['title'] ?? "Untitled"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PDFViewerScreen(pdfUrl: article['pdfUrl'] ?? "")),
                      ),
                    );
                  },
                ),
    );
  }
}
