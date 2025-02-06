class Post {
  final String userId;
  final String petName;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final int likes;

  Post({
    required this.userId,
    required this.petName,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.likes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petName': petName,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      userId: map['userId'] ?? '',
      petName: map['petName'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      likes: map['likes']?.toInt() ?? 0,
    );
  }
}