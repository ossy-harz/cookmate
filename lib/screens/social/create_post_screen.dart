import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../models/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CreatePostScreen extends StatefulWidget {
  final String? postId;

  const CreatePostScreen({Key? key, this.postId}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _mediaFile;
  String? _mediaType;
  bool _isLoading = false;
  bool _isEditing = false;
  PostModel? _existingPost;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _isEditing = true;
      _loadExistingPost();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final socialService = Provider.of<SocialService>(context, listen: false);
      final post = await socialService.getPostByIdOnce(widget.postId!);

      if (post != null) {
        setState(() {
          _existingPost = post;
          _contentController.text = post.content;
          // Note: We don't load the existing media file as it's already uploaded
          // We'll just keep the reference to it
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _mediaType = 'image';

        // Clear video controllers if they exist
        _videoPlayerController?.dispose();
        _chewieController?.dispose();
        _videoPlayerController = null;
        _chewieController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _mediaType = 'video';
      });

      // Initialize video player
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_mediaFile != null && _mediaType == 'video') {
      _videoPlayerController = VideoPlayerController.file(_mediaFile!);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        autoInitialize: true,
      );

      setState(() {});
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _mediaFile == null && _existingPost?.mediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or media')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final socialService = Provider.of<SocialService>(context, listen: false);

      final userData = await authService.getUserData();

      if (userData == null) {
        throw Exception('User data not found');
      }

      if (_isEditing) {
        // Update existing post
        await socialService.updatePost(
          postId: widget.postId!,
          content: _contentController.text.trim(),
          mediaFile: _mediaFile,
          mediaType: _mediaType,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully')),
        );
      } else {
        // Create new post
        await socialService.createPost(
          userId: userData.uid,
          userName: userData.displayName ?? 'Anonymous',
          content: _contentController.text.trim(),
          mediaFile: _mediaFile,
          mediaType: _mediaType,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
              : TextButton(
            onPressed: _submitPost,
            child: Text(
              _isEditing ? 'Update' : 'Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content TextField
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Share your cooking experience...',
                border: InputBorder.none,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Media Preview
            if (_mediaFile != null || (_existingPost?.mediaUrl != null && !_isEditing))
              Stack(
                children: [
                  // Media Content
                  if (_mediaFile != null)
                    _mediaType == 'image'
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _mediaFile!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    )
                        : _chewieController != null
                        ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    )
                        : const Center(child: CircularProgressIndicator())
                  else if (_existingPost?.mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _existingPost!.mediaUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),

                  // Remove Media Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _mediaFile = null;
                            _mediaType = null;
                            _videoPlayerController?.dispose();
                            _chewieController?.dispose();
                            _videoPlayerController = null;
                            _chewieController = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Media Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Add Video'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitPost,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            _isEditing ? 'Update Post' : 'Create Post',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

