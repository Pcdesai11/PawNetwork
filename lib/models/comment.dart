import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    // Handle different timestamp formats from Firestore
    DateTime timestamp;
    final timestampData = map['timestamp'];

    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate();
    } else if (timestampData == null) {
      timestamp = DateTime.now(); // Fallback for missing timestamp
    } else {
      try {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
      } catch (e) {
        print('Error parsing timestamp: $e');
        timestamp = DateTime.now(); // Fallback
      }
    }

    return Comment(
      id: map['id'] as String,
      postId: map['postId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userAvatar: map['userAvatar'] as String,
      content: map['content'] as String,
      timestamp: timestamp,
    );
  }}