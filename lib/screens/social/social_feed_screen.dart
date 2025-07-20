
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../models/post_model.dart';
import '../../widgets/glass_card.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({Key? key}) : super(key: key);

  @override
  _SocialFeedScreenState createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CookMate Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const Center(child: Text('User data not found'));
          }

          return StreamBuilder<List<PostModel>>(
            stream: Provider.of<SocialService>(context).getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No posts yet',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Be the first to share your cooking journey!',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-post');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Post'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, post, userData.uid);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-post');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post, String currentUserId) {
    final theme = Theme.of(context);
    final socialService = Provider.of<SocialService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: post.authorPhotoUrl != null
                      ? NetworkImage(post.authorPhotoUrl!)
                      : null,
                  child: post.authorPhotoUrl == null
                      ? Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Post Actions
                if (post.authorId == currentUserId)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/edit-post',
                          arguments: post.id,
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Post Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post.content,
                style: theme.textTheme.bodyLarge,
              ),
            ),

          // Post Media
          if (post.mediaUrl != null)
            post.mediaType == 'image'
                ? Image.network(
              post.mediaUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            )
                : _buildVideoPlayer(post.mediaUrl!),

          // Post Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.likes.contains(currentUserId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.likes.contains(currentUserId)
                            ? theme.colorScheme.secondary
                            : null,
                      ),
                      onPressed: () {
                        socialService.toggleLike(post.id, currentUserId);
                      },
                    ),
                    Text(
                      post.likes.length.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                // Comment Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/post-details',
                          arguments: post.id,
                        );
                      },
                    ),
                    Text(
                      post.commentCount.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                // Share Button
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share post
                  },
                ),
              ],
            ),
          ),

          // Comments Preview
          if (post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/post-details',
                    arguments: post.id,
                  );
                },
                child: Text(
                  'View all ${post.commentCount} comments',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: VideoPlayerWidget(videoUrl: videoUrl),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final socialService = Provider.of<SocialService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                socialService.deletePost(post.id);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted'),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? Chewie(controller: _chewieController!)
        : const Center(
      child: CircularProgressIndicator(),
    );
  }
}

