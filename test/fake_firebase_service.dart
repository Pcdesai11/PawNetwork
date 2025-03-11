import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:flutter/foundation.dart';

import 'widget_test.dart';

class MockFirebaseStorage {
  Future<String> getDownloadURL(String path) async {
    return 'https://fake-storage.example.com/$path';
  }

// Add other methods as needed
}


  class FakeFirebaseService {
  late final FakeFirebaseFirestore firestore;
  late final MockFirebaseAuth auth;
  late final MockFirebaseStorage storage;
  late final MockUser currentUser;

  /// Creates a new instance with optional parameters to customize the fake services
  FakeFirebaseService({
    String userId = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String photoURL = 'test_avatar_url',
    bool isSignedIn = true,
  }) {
    firestore = FakeFirebaseFirestore();

    currentUser = MockUser(
      uid: userId,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
    );

    auth = MockFirebaseAuth(
      signedIn: isSignedIn,
      mockUser: currentUser,
    );

    storage = MockFirebaseStorage();
  }

  /// Populates the fake Firestore with sample posts data
  Future<List<String>> populateSamplePosts({int count = 5}) async {
    final List<String> postIds = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final postRef = await firestore.collection('posts').add({
        'userId': i % 2 == 0 ? currentUser.uid : 'other-user-$i',
        'userName': i % 2 == 0 ? currentUser.displayName : 'Other User $i',
        'userAvatar': i % 2 == 0 ? currentUser.photoURL : 'avatar_$i.jpg',
        'petName': 'Pet ${i + 1}',
        'content': 'Sample post content ${i + 1}',
        'imageUrl': i % 2 == 0 ? 'post_image_$i.jpg' : null,
        'timestamp': now.subtract(Duration(hours: i)),
        'likes': i,
        'commentCount': i,
        'likedBy': i > 0 ? List.generate(i, (index) => 'user-$index') : [],
      });

      postIds.add(postRef.id);

      // Add some comments to each post
      if (i > 0) {
        for (int j = 0; j < i; j++) {
          await firestore
              .collection('posts')
              .doc(postRef.id)
              .collection('comments')
              .add({
            'postId': postRef.id,
            'userId': j % 2 == 0 ? currentUser.uid : 'commenter-$j',
            'userName': j % 2 == 0 ? currentUser.displayName : 'Commenter $j',
            'userAvatar': j % 2 == 0 ? currentUser.photoURL : 'commenter_avatar_$j.jpg',
            'content': 'This is comment $j on post $i',
            'timestamp': now.subtract(Duration(hours: i, minutes: j * 10)),
          });
        }
      }
    }

    return postIds;
  }

  /// Clears all data in the fake Firestore
  Future<void> clearData() async {
    final collections = ['posts', 'users', 'pets'];

    for (final collection in collections) {
      final snapshot = await firestore.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Signs in a user with the provided credentials
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
}