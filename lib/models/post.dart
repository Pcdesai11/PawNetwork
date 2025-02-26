import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Post {
  final String id;
  final String userId;
  final String userAvatar;
  final String petName;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final int likes;
  final int commentCount;
  final bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.userAvatar,
    required this.petName,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
    required this.isLiked,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Handle potential null or missing fields with defaults
      return Post(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        userAvatar: map['userAvatar'] ?? 'default_avatar_url',
        petName: map['petName'] ?? 'Unknown Pet',
        content: map['content'] ?? '',
        imageUrl: map['imageUrl'],
        timestamp: _parseTimestamp(map['timestamp']),
        likes: map['likes'] is int ? map['likes'] : 0,
        commentCount: map['commentCount'] is int ? map['commentCount'] : 0,
        isLiked: currentUser != null &&
            map['likedBy'] is List &&
            (map['likedBy'] as List).contains(currentUser.uid),
      );
    } catch (e) {
      print('Error parsing Post: $e');
      // Return a fallback Post object instead of throwing an exception
      // This prevents the entire stream from failing due to one bad document
      return Post(
        id: map['id'] ?? 'error',
        userId: '',
        userAvatar: 'default_avatar_url',
        petName: 'Error Loading Post',
        content: 'This post could not be loaded correctly.',
        imageUrl: null,
        timestamp: DateTime.now(),
        likes: 0,
        commentCount: 0,
        isLiked: false,
      );
    }
  }

  // Helper method to safely parse timestamp from various formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userAvatar': userAvatar,
      'petName': petName,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}