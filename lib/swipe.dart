import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pdf.dart';
import 'saved_articles_screen.dart'; 
import 'comments.dart';


String processText(String text) {
  return text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<Map<String, dynamic>> articles = [];
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Set<String> savedArticleIds = {}; 
  int articlesPerPage = 10; 
  DocumentSnapshot? lastDocument; 
  bool isFetchingMore = false; 
  bool hasMoreArticles = true; 

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    fetchArticles();
    fetchSavedArticles();
  }

  Future<void> fetchArticles() async {
  if (!hasMoreArticles || isFetchingMore) return; 
  setState(() => isFetchingMore = true);

  try {
    Query query = FirebaseFirestore.instance
        .collection('articles')
        .orderBy('timestamp', descending: true)
        .limit(articlesPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        lastDocument = snapshot.docs.last; 
        articles.addAll(snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
      });
    } else {
      setState(() {
        hasMoreArticles = false; 
      });
    }
  } catch (e) {
    print('Error fetching articles: $e');
  } finally {
    setState(() => isFetchingMore = false);
  }
}

  Future<void> fetchSavedArticles() async {
    if (user == null) return;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('saved_articles')
          .get();

      setState(() {
        savedArticleIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      print('Error fetching saved articles: $e');
    }
  }

  Future<void> toggleSaveArticle(String articleId, Map<String, dynamic> article) async {
    if (user == null) return;

    final savedArticlesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('saved_articles');

    if (savedArticleIds.contains(articleId)) {
      await savedArticlesRef.doc(articleId).delete();
      setState(() {
        savedArticleIds.remove(articleId);
      });
    } else {
      await savedArticlesRef.doc(articleId).set(article);
      setState(() {
        savedArticleIds.add(articleId);
      });
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

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Articles"),
        backgroundColor: const Color.fromARGB(220, 255, 98, 98),
        
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              accountName: Text(user?.displayName ?? "Guest"),
              accountEmail: Text(user?.email ?? "No Email"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user?.photoURL ?? ""),
                backgroundColor: Colors.grey,
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text("Saved Articles"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedArticlesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sign Out"),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                    hasMoreArticles &&
                    !isFetchingMore) {
                  fetchArticles(); 
                }
                return false;
              },
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  final articleId = article['id'] ?? index.toString();
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  processText(article['title'] ?? 'No Title'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      savedArticleIds.contains(articleId) ? Icons.bookmark : Icons.bookmark_border,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => toggleSaveArticle(articleId, article),
                                  ),
                                  const SizedBox(height: 28),
                                  IconButton(
                                    icon: const Icon(Icons.comment, color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CommentScreen(
                                            articleId: articleId,
                                            articleTitle: article['title'] ?? 'No Title',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text(
                              processText(article['abstract'] ?? 'No Summary Available'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            )
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => openPDF(article['pdfUrl'] ?? ''),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(220, 255, 98, 98), shape: LinearBorder.start()),
                            child: const Text("Open PDF", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    ));
  }
}
