
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        data['isLiked'] = (data['likedBy'] ?? [])
            .contains(_auth.currentUser?.uid);
        return Post.fromMap(data);
      }).toList();
    });
  }


  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromMap(data);
      }).toList();
    });
  }


  Future<void> toggleLike(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final postRef = _firestore.collection('posts').doc(postId);

    return _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) throw Exception('Post not found');

      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(1),
        });
      }
    });
  }


  Future<void> addComment(String postId, String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final commentData = {
      'postId': postId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userAvatar': user.photoURL ?? 'default_avatar_url',
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore.runTransaction((transaction) async {

      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      transaction.set(commentRef, commentData);


      final postRef = _firestore.collection('posts').doc(postId);
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }


  Future<void> refreshPosts() async {

    return Future.delayed(Duration(milliseconds: 500));
  }


  Future<void> createPost({
    required String petName,
    required String content,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final postData = {
      'userId': user.uid,
      'userAvatar': user.photoURL ?? 'default_avatar_url',
      'petName': petName,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'likes': 0,
      'commentCount': 0,
      'likedBy': [],
    };

    await _firestore.collection('posts').add(postData);
  }


  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (postDoc.data()?['userId'] != user.uid) {
      throw Exception('Not authorized to delete this post');
    }

    await _firestore.collection('posts').doc(postId).delete();
  }
}