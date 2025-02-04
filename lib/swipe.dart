import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf.dart'; // PDF viewer screen

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<Map<String, dynamic>> articles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        articles = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching articles: $e');
      setState(() => isLoading = false);
    }
  }

  void openPDF(String url) {
    if (url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewerScreen(pdfUrl: url)),
      );
    } else {
      print("Invalid PDF URL");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? const Center(child: Text("No articles found!", style: TextStyle(fontSize: 20)))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];

                    return Column(
                      children: [
                        // Header Section
                        Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          child: Text(
                            article['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        // Content Section
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Text(
                              article['abstract'] ?? 'No Summary Available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),

                        // Button Section
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => openPDF(article['pdfUrl'] ?? ''),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(79, 216, 184, 184)),
                            child: const Text("Open PDF", style: TextStyle(color: Color.fromARGB(255, 138, 51, 51), fontSize: 16)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
