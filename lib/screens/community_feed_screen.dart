import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../services/post_service.dart';
import 'create_post_screen.dart'; // Import the new screen

class CommunityFeedScreen extends StatefulWidget {
  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late Stream<List<Post>> _postsStream;
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.getPostsStream();
  }

  Future<void> _handleLike(Post post) async {
    try {
      await _postService.toggleLike(post.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like post: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleShare(Post post) async {
    try {
      await Share.share(
        'Check out ${post.petName}\'s post on PawNetwork!\n${post.imageUrl ?? ""}',
        subject: 'PawNetwork Post',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share post: ${e.toString()}')),
      );
    }
  }

  void _showCommentDialog(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            StreamBuilder<List<Comment>>(
              stream: _postService.getCommentsStream(post.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Comment error: ${snapshot.error}');
                  return Center(child: Text('Error loading comments: ${snapshot.error.toString().substring(0, 100)}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(comment.userAvatar),
                        ),
                        title: Text(comment.userName),
                        subtitle: Text(comment.content),
                        trailing: Text(
                          _formatTimestamp(comment.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      if (_commentController.text.trim().isEmpty) return;

                      try {
                        await _postService.addComment(
                          post.id,
                          _commentController.text.trim(),
                        );
                        _commentController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to post comment: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PawNetwork Feed'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Feed error: ${snapshot.error}');
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to share your pet\'s adventures!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreatePostScreen()),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Create Post'),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _postService.refreshPosts(),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
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
                            backgroundImage: NetworkImage(post.userAvatar),
                          ),
                          title: Text(post.petName),
                          subtitle: Text(_formatTimestamp(post.timestamp)),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ),
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(post.imageUrl!),
                                fit: BoxFit.cover,
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
                              icon: Icon(
                                post.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post.isLiked ? Colors.red : null,
                              ),
                              onPressed: () => _handleLike(post),
                            ),
                            Text('${post.likes}'),
                            IconButton(
                              icon: Icon(Icons.comment_outlined),
                              onPressed: () => _showCommentDialog(post),
                            ),
                            Text('${post.commentCount}'),
                            IconButton(
                              icon: Icon(Icons.share_outlined),
                              onPressed: () => _handleShare(post),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}