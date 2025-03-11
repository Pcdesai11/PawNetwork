import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pawnetwork/services/post_service.dart';
import 'package:pawnetwork/models/post.dart';
import 'package:pawnetwork/models/comment.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

// Import the fake Firebase service
import 'fake_firebase_service.dart';
// Import the Firebase testing setup
import 'firebase_simple_setup.dart';

// Modified MockPostService to use our FakeFirebaseService
class MockPostService extends PostService {
  final FakeFirebaseService firebaseService;

  MockPostService({required this.firebaseService});

  @override
  FirebaseFirestore get _firestore => firebaseService.firestore;

  @override
  FirebaseAuth get _auth => firebaseService.auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseService firebaseService;
  late MockPostService postService;

  setUpAll(() async {
    // Initialize Firebase mocks for testing
    await setupFirebaseForTesting();
  });

  setUp(() {
    // Initialize our fake Firebase service
    firebaseService = FakeFirebaseService(
      userId: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoURL: 'test_avatar_url',
      isSignedIn: true,
    );

    // Create mock service with injected dependency
    postService = MockPostService(
      firebaseService: firebaseService,
    );
  });

  tearDown(() async {
    // Clean up after each test
    await firebaseService.clearData();
  });

  group('PostService Tests', () {
    test('getPostsStream should return a stream of posts sorted by timestamp', () async {
      // Arrange - Use the helper method to populate sample data
      await firebaseService.populateSamplePosts(count: 2);

      // Act
      final stream = postService.getPostsStream(limit: 10);

      // Assert
      final posts = await stream.first;
      expect(posts.length, 2);
      // Posts should be sorted by timestamp (most recent first)
      expect(posts[0].petName, 'Pet 1');
      expect(posts[1].petName, 'Pet 2');
    });

    test('getMorePosts should fetch posts after the last post', () async {
      // Arrange - Populate with 5 sample posts
      final postIds = await firebaseService.populateSamplePosts(count: 5);

      // Act
      final result = await postService.getMorePosts(
          lastPostId: postIds[2], // Get posts after the third post
          limit: 2
      );

      // Assert
      expect(result.length, 2);
      expect(result[0].petName, 'Pet 4');
      expect(result[1].petName, 'Pet 5');
    });

    test('getCommentsStream should return comments for a specific post', () async {
      // Arrange - Create a post with comments
      final postIds = await firebaseService.populateSamplePosts(count: 3);
      final postId = postIds[2]; // This post should have 2 comments

      // Act
      final stream = postService.getCommentsStream(postId);

      // Assert
      final comments = await stream.first;
      expect(comments.length, 2);
      // Comments should be sorted by timestamp (most recent first)
      expect(comments[0].content, contains('comment 1'));
      expect(comments[1].content, contains('comment 0'));
    });

    test('toggleLike should add user to likedBy array when liking', () async {
      // Arrange
      final postRef = await firebaseService.firestore.collection('posts').add({
        'userId': 'other-user',
        'userAvatar': 'avatar',
        'petName': 'Pet',
        'content': 'Post content',
        'timestamp': DateTime.now(),
        'likes': 0,
        'commentCount': 0,
        'likedBy': [],
      });

      // Act
      await postService.toggleLike(postRef.id);

      // Assert
      final updatedDoc = await firebaseService.firestore.collection('posts').doc(postRef.id).get();
      expect(updatedDoc.data()!['likes'], 1);
      expect(updatedDoc.data()!['likedBy'], contains('test-user-id'));
    });

    test('toggleLike should remove user from likedBy array when unliking', () async {
      // Arrange
      final postRef = await firebaseService.firestore.collection('posts').add({
        'userId': 'other-user',
        'userAvatar': 'avatar',
        'petName': 'Pet',
        'content': 'Post content',
        'timestamp': DateTime.now(),
        'likes': 1,
        'commentCount': 0,
        'likedBy': ['test-user-id'],
      });

      // Act
      await postService.toggleLike(postRef.id);

      // Assert
      final updatedDoc = await firebaseService.firestore.collection('posts').doc(postRef.id).get();
      expect(updatedDoc.data()!['likes'], 0);
      expect(updatedDoc.data()!['likedBy'], isEmpty);
    });

    test('addComment should add a comment to the post and increment commentCount', () async {
      // Arrange
      final postRef = await firebaseService.firestore.collection('posts').add({
        'userId': 'post-owner',
        'userAvatar': 'avatar',
        'petName': 'Pet',
        'content': 'Post content',
        'timestamp': DateTime.now(),
        'likes': 0,
        'commentCount': 0,
        'likedBy': [],
      });

      // Act
      await postService.addComment(postRef.id, 'New comment content');

      // Assert
      final updatedPost = await firebaseService.firestore.collection('posts').doc(postRef.id).get();
      expect(updatedPost.data()!['commentCount'], 1);

      final commentsSnapshot = await firebaseService.firestore
          .collection('posts')
          .doc(postRef.id)
          .collection('comments')
          .get();

      expect(commentsSnapshot.docs.length, 1);
      expect(commentsSnapshot.docs.first.data()['content'], 'New comment content');
      expect(commentsSnapshot.docs.first.data()['userId'], 'test-user-id');
    });

    test('createPost should add a new post to the database', () async {
      // Act
      await postService.createPost(
        petName: 'Test Pet',
        content: 'Test content',
        imageUrl: 'test_image.jpg',
      );

      // Assert
      final querySnapshot = await firebaseService.firestore.collection('posts').get();
      expect(querySnapshot.docs.length, 1);

      final postData = querySnapshot.docs.first.data();
      expect(postData['userId'], 'test-user-id');
      expect(postData['petName'], 'Test Pet');
      expect(postData['content'], 'Test content');
      expect(postData['imageUrl'], 'test_image.jpg');
      expect(postData['likes'], 0);
      expect(postData['commentCount'], 0);
      expect(postData['likedBy'], isEmpty);
    });

    test('deletePost should remove a post when user is the owner', () async {
      // Arrange - Create a post owned by the test user
      final postIds = await firebaseService.populateSamplePosts(count: 3);
      final userPostId = postIds[0]; // This should be a post by the test user

      // Act
      await postService.deletePost(userPostId);

      // Assert
      final docSnapshot = await firebaseService.firestore.collection('posts').doc(userPostId).get();
      expect(docSnapshot.exists, false);
    });

    test('deletePost should throw an exception when user is not the owner', () async {
      // Arrange - Create a post owned by another user
      final postIds = await firebaseService.populateSamplePosts(count: 3);
      final otherUserPostId = postIds[1]; // This should be a post by another user

      // Act & Assert
      expect(() => postService.deletePost(otherUserPostId), throwsException);

      // Verify post still exists
      final docSnapshot = await firebaseService.firestore.collection('posts').doc(otherUserPostId).get();
      expect(docSnapshot.exists, true);
    });

    test('refreshPosts should complete without errors', () async {
      // Act & Assert
      expect(postService.refreshPosts(), completes);
    });

    test('user can sign out and sign in again', () async {
      // Arrange - Create some posts while signed in
      await firebaseService.populateSamplePosts(count: 2);

      // Act - Sign out
      await firebaseService.signOut();

      // Assert - User should be signed out
      expect(firebaseService.auth.currentUser, isNull);

      // Act - Sign in again
      await firebaseService.signIn(
        email: 'test@example.com',
        password: 'password123', // This is ignored by the mock
      );

      // Assert - User should be signed in again
      expect(firebaseService.auth.currentUser, isNotNull);
      expect(firebaseService.auth.currentUser?.uid, 'test-user-id');
    });
  });
}