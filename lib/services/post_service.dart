import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Updated method to get initial posts stream with pagination
  Stream<List<Post>> getPostsStream({int limit = 10}) {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return Post.fromMap(data);
        } catch (e) {
          print('Error parsing post ${doc.id}: $e');

          // Return a placeholder post instead of throwing an error
          return Post(
            id: doc.id,
            userId: '',
            userAvatar: 'default_avatar_url',
            petName: 'Error Loading Post',
            content: 'This post could not be loaded correctly.',
            timestamp: DateTime.now(),
            likes: 0,
            commentCount: 0,
            isLiked: false,
          );
        }
      }).toList();
    });
  }

// New method to get more posts for pagination
  Future<List<Post>> getMorePosts({required String lastPostId, int limit = 10}) async {
    // First, get the document snapshot of the last post
    final lastPostDoc = await _firestore
        .collection('posts')
        .doc(lastPostId)
        .get();

    if (!lastPostDoc.exists) {
      return [];
    }

    // Query for posts that come after the last post
    final querySnapshot = await _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastPostDoc)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        return Post.fromMap(data);
      } catch (e) {
        print('Error parsing post ${doc.id}: $e');

        // Return a placeholder post instead of throwing an error
        return Post(
          id: doc.id,
          userId: '',
          userAvatar: 'default_avatar_url',
          petName: 'Error Loading Post',
          content: 'This post could not be loaded correctly.',
          timestamp: DateTime.now(),
          likes: 0,
          commentCount: 0,
          isLiked: false,
        );
      }
    }).toList();
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
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return Comment.fromMap(data);
        } catch (e) {
          print('Error parsing comment ${doc.id}: $e');
          // Return a placeholder comment instead of throwing an error
          return Comment(
            id: doc.id,
            postId: postId,
            userId: '',
            userName: 'Unknown User',
            userAvatar: 'default_avatar_url',
            content: 'Error loading comment',
            timestamp: DateTime.now(),
          );
        }
      }).toList();
    });
  }

  Future<void> toggleLike(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final postRef = _firestore.collection('posts').doc(postId);

      // First check if the document exists
      final docSnapshot = await postRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Post not found');
      }

      // Get the current likedBy array or initialize it if it doesn't exist
      List<String> likedBy = List<String>.from(docSnapshot.data()?['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        // Unlike
        await postRef.update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await postRef.update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      throw e; // Re-throw to show error in UI
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final commentData = {
        'postId': postId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL ?? 'default_avatar_url',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // First check if the post exists
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      // Add the comment
      await _firestore.collection('posts').doc(postId).collection('comments').add(commentData);

      // Update the comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding comment: $e');
      throw e; // Re-throw to show error in UI
    }
  }

  // Replace this method in your post_service.dart file:

  Future<void> refreshPosts() async {
    try {
      // Provide a real implementation to refresh posts
      // This will clear any cached data and force a fresh fetch
      // Wait a moment to give Firebase time to update
      await Future.delayed(Duration(milliseconds: 500));

      // You could perform additional cache clearing here if needed
      return;
    } catch (e) {
      print('Error refreshing posts: $e');
      throw e;
    }
  }

  Future<void> createPost({
    required String petName,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final postData = {
        'userId': user.uid,
        'userAvatar': user.photoURL ?? 'default_avatar_url',
        'petName': petName,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'commentCount': 0,
        'likedBy': [],
      };

      await _firestore.collection('posts').add(postData);
    } catch (e) {
      print('Error creating post: $e');
      throw e; // Re-throw to show error in UI
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      if (postDoc.data()?['userId'] != user.uid) {
        throw Exception('Not authorized to delete this post');
      }

      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
      throw e; // Re-throw to show error in UI
    }
  }
}