import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class PostViewPage extends StatelessWidget {
  final Function(File photo) onWantToGoPressed;

  const PostViewPage({super.key, required this.onWantToGoPressed});


  Future<void> _toggleLike(String postId, String currentUserId) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);

    final postSnapshot = await postRef.get();
    final userSnapshot = await userRef.get();

    if (!postSnapshot.exists || !userSnapshot.exists) return;

    final postLikes = List<String>.from(postSnapshot['likedBy'] ?? []);

    if (postLikes.contains(currentUserId)) {
      // いいねを取り消す
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([currentUserId]),
        'likeCount': FieldValue.increment(-1),
      });
      await userRef.update({
        'likedPosts': FieldValue.arrayRemove([postId]),
      });
    } else {
      // いいねを追加
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([currentUserId]),
        'likeCount': FieldValue.increment(1),
      });
      await userRef.update({
        'likedPosts': FieldValue.arrayUnion([postId]),
      });
    }
  }

  Future<void> _refreshPosts() async {
    // Firebaseのデータはリアルタイムストリームで自動的に更新されるので、
    // 実際には特に操作は不要。
    // ただし、デモ目的で少し遅延を追加する。
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿一覧'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('投稿がありません'));
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final postId = post.id;
                final likeCount = post['likeCount'] ?? 0;
                final likedBy = List<String>.from(post['likedBy'] ?? []);

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトルと詳細情報
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title'],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '${post['userName']} - ${post['description']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // 投稿画像
                      if (post['imageUrl'] != null)
                        Image.network(
                          post['imageUrl'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      else
                        const SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      // ボタンセクション
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // いいねボタン
                            TextButton.icon(
                              onPressed: () => _toggleLike(postId, currentUserId),
                              icon: Icon(
                                Icons.thumb_up,
                                color: likedBy.contains(currentUserId)
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              label: Text('いいね ($likeCount)'),
                            ),
                            // 行ってみたいボタン
                            TextButton.icon(
                              onPressed: () async {
                                if (post['imageUrl'] != null) {
                                  // 画像URLをダウンロードして一時ファイルとして保存
                                  final imageUrl = post['imageUrl'];
                                  final response = await HttpClient().getUrl(Uri.parse(imageUrl));
                                  final bytes = await consolidateHttpClientResponseBytes(await response.close());
                                  final tempFile = File('${(await getTemporaryDirectory()).path}/temp_image.jpg');
                                  await tempFile.writeAsBytes(bytes);

                                  onWantToGoPressed(tempFile);
                                } else {
                                  // 画像がない場合のエラーメッセージ
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("画像がありません"),
                                      content: const Text("位置情報を取得するには画像が必要です。"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.location_on, color: Colors.green),
                              label: Text("行ってみたい"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}