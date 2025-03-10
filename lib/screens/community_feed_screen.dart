import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../services/post_service.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late Stream<List<Post>> _postsStream;
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();

  // For pagination
  final int _postsPerPage = 10;
  String? _lastPostId;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;
  List<Post> _allPosts = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializePosts();
    _scrollController.addListener(_scrollListener);
  }

  void _initializePosts() {
    _postsStream = _postService.getPostsStream(limit: _postsPerPage);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _allPosts.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _lastPostId = _allPosts.last.id;
      List<Post> morePosts = await _postService.getMorePosts(
        lastPostId: _lastPostId!,
        limit: _postsPerPage,
      );

      if (morePosts.isEmpty) {
        setState(() {
          _hasMorePosts = false;
        });
      } else {
        setState(() {
          _allPosts.addAll(morePosts);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more posts: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
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
                Expanded(
                  child: StreamBuilder<List<Comment>>(
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

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(comment.userAvatar),
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Failed to load avatar: $exception');
                              },
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(comment.userName),
                            subtitle: Text(comment.content),
                            trailing: Text(
                              _formatTimestamp(comment.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      );
                    },
                  ),
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
                            Navigator.pop(context); // Close dialog after posting comment
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
          );
        },
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
      // Replace the following code in your CommunityFeedScreen.dart file
// Find the FloatingActionButton section in the build method and replace it with this:

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );

          // If post was successfully created, refresh the feed
          if (result == true) {
            await _postService.refreshPosts();
            setState(() {
              _lastPostId = null;
              _hasMorePosts = true;
              _initializePosts();
            });
          }
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

          _allPosts = snapshot.data!;

          if (_allPosts.isEmpty) {
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
            onRefresh: () async {
              await _postService.refreshPosts();
              setState(() {
                _lastPostId = null;
                _hasMorePosts = true;
                _initializePosts();
              });
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _allPosts.length + (_hasMorePosts ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _allPosts.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final post = _allPosts[index];
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
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Failed to load avatar: $exception');
                            },
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(post.petName),
                          subtitle: Text(_formatTimestamp(post.timestamp)),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ),
                        // Find this section in the CommunityFeedScreen.dart file
// Replace the image container with this improved version:

                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                          Container(
                            height: 250,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Loading indicator shown until image loads
                                  Center(child: CircularProgressIndicator()),

                                  // Image with proper error handling
                                  Image.network(
                                    post.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        // Image is fully loaded, return the image
                                        return child;
                                      }
                                      // Image is still loading, show progress
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}