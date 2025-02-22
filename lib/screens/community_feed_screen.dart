import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../models/post.dart';

class CommunityFeedScreen extends StatelessWidget {
  final List<Post> _posts = [
    Post(
      userId: '1',
      petName: 'Max',
      content: 'Enjoying a sunny day at the park! 🐕',
      imageUrl: 'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 15,
    ),
    Post(
      userId: '2',
      petName: 'Luna',
      content: 'First day at puppy school 🎓',
      imageUrl: 'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      likes: 24,
    ),
    Post(
      userId: '3',
      petName: 'Luna',
      content: 'First day at puppy school 🎓',
      imageUrl: 'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg',
      timestamp: DateTime.now().subtract(Duration(hours: 9)),
      likes: 24,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PawNetwork Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 500),
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(post.imageUrl!),
                      ),
                      title: Text(post.petName),
                      subtitle: Text(
                        '${post.timestamp.difference(DateTime.now()).inHours.abs()} hours ago',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                    if (post.imageUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(post.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(post.content),
                    ),
                    Divider(height: 1),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite_border),
                          onPressed: () {},
                        ),
                        Text('${post.likes}'),
                        IconButton(
                          icon: Icon(Icons.comment_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.share_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
