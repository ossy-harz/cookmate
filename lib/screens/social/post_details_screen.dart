import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final socialService = Provider.of<SocialService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
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

          return StreamBuilder<PostModel?>(
            stream: socialService.getPostById(widget.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final post = snapshot.data;

              if (post == null) {
                return const Center(child: Text('Post not found'));
              }

              return Column(
                children: [
                  // Post Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post Card
                          Card(
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Post Header
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // User Avatar
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                        child: Text(
                                          post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // User Name and Post Time
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
                                              timeago.format(post.createdAt),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Post Menu
                                      if (post.authorId == userData.uid)
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              Navigator.pushNamed(
                                                context,
                                                '/create-post',
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
                                  _buildMediaContent(context, post),

                                // Post Actions
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Like Button
                                      IconButton(
                                        icon: Icon(
                                          post.likes.contains(userData.uid)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: post.likes.contains(userData.uid)
                                              ? Colors.red
                                              : theme.colorScheme.onSurface,
                                        ),
                                        onPressed: () {
                                          if (post.likes.contains(userData.uid)) {
                                            socialService.unlikePost(post.id, userData.uid);
                                          } else {
                                            socialService.likePost(post.id, userData.uid);
                                          }
                                        },
                                      ),
                                      Text(
                                        post.likes.length.toString(),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),

                                      // Comment Button
                                      IconButton(
                                        icon: const Icon(Icons.comment_outlined),
                                        onPressed: () {
                                          // Focus on comment field
                                          FocusScope.of(context).requestFocus(FocusNode());
                                        },
                                      ),
                                      Text(
                                        post.commentCount.toString(),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),

                                      // Share Button
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {
                                          // Share post
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Sharing coming soon!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Comments Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Comments',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Comments List
                          StreamBuilder<List<CommentModel>>(
                            stream: socialService.getPostComments(post.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              final comments = snapshot.data ?? [];

                              if (comments.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No comments yet. Be the first to comment!',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return _buildCommentItem(context, comment, userData);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Comment Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            userData.displayName != null && userData.displayName!.isNotEmpty
                                ? userData.displayName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: theme.colorScheme.primary,
                          onPressed: () {
                            if (_commentController.text.trim().isNotEmpty) {
                              socialService.addComment(
                                postId: post.id,
                                userId: userData.uid,
                                userName: userData.displayName ?? 'Anonymous',
                                content: _commentController.text.trim(),
                              );
                              _commentController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, CommentModel comment, UserModel currentUser) {
    final theme = Theme.of(context);
    final socialService = Provider.of<SocialService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        comment.likes.contains(currentUser.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: comment.likes.contains(currentUser.uid)
                            ? Colors.red
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      label: Text(
                        comment.likes.length.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        if (comment.likes.contains(currentUser.uid)) {
                          socialService.unlikeComment(comment.id, currentUser.uid);
                        } else {
                          socialService.likeComment(comment.id, currentUser.uid);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    if (comment.userId == currentUser.uid)
                      TextButton.icon(
                        icon: Icon(
                          Icons.delete,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'Delete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _showDeleteCommentConfirmation(context, comment);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, PostModel post) {
    if (post.mediaType == 'image') {
      return CachedNetworkImage(
        imageUrl: post.mediaUrl!,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (post.mediaType == 'video') {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoPostPlayer(videoUrl: post.mediaUrl!),
      );
    }

    return const SizedBox.shrink();
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
                Navigator.of(context).pop(); // Go back to feed

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
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

  void _showDeleteCommentConfirmation(BuildContext context, CommentModel comment) {
    final theme = Theme.of(context);
    final socialService = Provider.of<SocialService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                socialService.deleteComment(comment.id);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment deleted')),
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

class VideoPostPlayer extends StatefulWidget {
  final String videoUrl;

  const VideoPostPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPostPlayerState createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
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
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      placeholder: const Center(child: CircularProgressIndicator()),
      autoInitialize: true,
    );

    setState(() {
      _isInitialized = true;
    });
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
        : const Center(child: CircularProgressIndicator());
  }
}

