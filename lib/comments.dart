import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentScreen extends StatelessWidget {
  final String articleId;
  final String articleTitle;

  CommentScreen({required this.articleId, required this.articleTitle});

  final TextEditingController _commentController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  void postComment(String content) async {
    if (content.isEmpty || user == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(articleId)
        .collection('comments');

    await commentRef.add({
      'content': content,
      'userId': user!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'downvotes': 0,
    });
    _commentController.clear();
  }

  void voteComment(String commentId, bool isUpvote) async {
    final commentRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    await commentRef.update({
      isUpvote ? 'upvotes' : 'downvotes': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(articleTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('articles')
                  .doc(articleId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment['content']),
                      subtitle: Text('Upvotes: ${comment['upvotes']} | Downvotes: ${comment['downvotes']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up),
                            onPressed: () => voteComment(comment.id, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.thumb_down),
                            onPressed: () => voteComment(comment.id, false),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => postComment(_commentController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
