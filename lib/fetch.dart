import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Future<void> fetchAndStoreArxivArticles() async {
  final url = Uri.parse('http://export.arxiv.org/api/query?search_query=all:AI&sortBy=submittedDate&sortOrder=descending&max_results=10');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final entries = document.findAllElements('entry');

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      for (var entry in entries) {
        String title = entry.findElements('title').first.innerText.trim();
        String abstract = entry.findElements('summary').first.innerText.trim();
        String pdfUrl = entry.findElements('link').firstWhere(
          (element) => element.getAttribute('title') == 'pdf',
        ).getAttribute('href') ?? '';

        await firestore.collection('articles').doc(title).set({
          'title': title,
          'abstract': abstract,
          'pdfUrl': pdfUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  } catch (e) {
    print('Error fetching articles: $e');
  }
}
