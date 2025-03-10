import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Constants for validation
  static const int MAX_PET_NAME_LENGTH = 30;
  static const int MAX_CONTENT_LENGTH = 500;
  static const List<String> ALLOWED_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif'];
  static const int MAX_IMAGE_SIZE_MB = 5;

  File? _image;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;
  bool _enablePostButton = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to enable post button when valid input exists
    _petNameController.addListener(_updatePostButtonState);
    _contentController.addListener(_updatePostButtonState);
  }

  void _updatePostButtonState() {
    setState(() {
      _enablePostButton = _petNameController.text.trim().isNotEmpty &&
          _contentController.text.trim().isNotEmpty &&
          _petNameController.text.length <= MAX_PET_NAME_LENGTH &&
          _contentController.text.length <= MAX_CONTENT_LENGTH;
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Optimize image size for mobile
        maxHeight: 1200,
        imageQuality: 85, // Good quality but reduced file size
      );

      if (pickedFile != null) {
        // Validate file extension
        final extension = path.extension(pickedFile.path).toLowerCase().replaceAll('.', '');
        if (!ALLOWED_IMAGE_EXTENSIONS.contains(extension)) {
          setState(() {
            _errorMessage = 'Unsupported file type. Please use JPG, JPEG, PNG, or GIF.';
          });
          return;
        }

        // Validate file size
        final file = File(pickedFile.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > MAX_IMAGE_SIZE_MB) {
          setState(() {
            _errorMessage = 'Image too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is ${MAX_IMAGE_SIZE_MB}MB.';
          });
          return;
        }

        setState(() {
          _image = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'Failed to pick image: ${_getReadableError(e)}';
      });
    }
  }

  String _getReadableError(dynamic error) {
    String message = error.toString();

    // Handle common error types with more user-friendly messages
    if (message.contains('permission') || message.contains('denied')) {
      return 'Permission denied. Please grant storage access in settings.';
    } else if (message.contains('storage') || message.contains('space')) {
      return 'Not enough storage space available.';
    } else if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    // Return a simplified error message
    return message.length > 100 ? '${message.substring(0, 100)}...' : message;
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final fileName = path.basename(_image!.path);
      final destination = 'post_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final ref = FirebaseStorage.instance.ref().child(destination);
      final uploadTask = ref.putFile(_image!);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask.whenComplete(() {});

      setState(() {
        _isUploading = false;
      });

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _errorMessage = 'Failed to upload image: ${_getReadableError(e)}';
        _isUploading = false;
      });
      return null;
    }
  }

  bool _validateInputs() {
    // Validate pet name
    if (_petNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your pet name';
      });
      return false;
    }

    if (_petNameController.text.trim().length > MAX_PET_NAME_LENGTH) {
      setState(() {
        _errorMessage = 'Pet name cannot exceed $MAX_PET_NAME_LENGTH characters';
      });
      return false;
    }

    // Validate content
    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter post content';
      });
      return false;
    }

    if (_contentController.text.trim().length > MAX_CONTENT_LENGTH) {
      setState(() {
        _errorMessage = 'Post content cannot exceed $MAX_CONTENT_LENGTH characters';
      });
      return false;
    }

    return true;
  }

  Future<void> _createPost() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null && _errorMessage == null) {
          setState(() {
            _errorMessage = 'Failed to upload image. Please try again.';
            _isLoading = false;
          });
          return;
        }
      }

      await _postService.createPost(
        petName: _petNameController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
      );

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Add a small delay to ensure the post is saved before navigating back
      await Future.delayed(Duration(milliseconds: 500));

      // Close this screen and go back to community feed
      Navigator.pop(context, true); // Pass true to indicate successful post creation
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create post: ${_getReadableError(e)}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Add a persistent bottom button instead of in app bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -1),
              blurRadius: 4,
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: (_isLoading || _isUploading || !_enablePostButton) ? null : _createPost,
            child: _isLoading || _isUploading
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(_isUploading ? 'Uploading...' : 'Posting...'),
              ],
            )
                : Text('Post to Community Feed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),

            // Add a message at the top about posting to community
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.pets, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share your pet\'s moment with the PawNetwork community!',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            TextField(
              controller: _petNameController,
              decoration: InputDecoration(
                labelText: 'Pet Name',
                hintText: 'Enter your pet\'s name',
                counterText: '${_petNameController.text.length}/$MAX_PET_NAME_LENGTH',
                prefixIcon: Icon(Icons.pets),
              ),
              maxLength: MAX_PET_NAME_LENGTH,
              onChanged: (value) {
                // Force a rebuild to update the counter
                setState(() {});
              },
            ),

            SizedBox(height: 16),

            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: MAX_CONTENT_LENGTH,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'What\'s on your pet\'s mind?',
                alignLabelWithHint: true,
                counterText: '${_contentController.text.length}/$MAX_CONTENT_LENGTH',
              ),
              onChanged: (value) {
                // Force a rebuild to update the counter
                setState(() {});
              },
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isUploading) ? null : _pickImage,
                    icon: Icon(Icons.photo),
                    label: Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                if (_image != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: (_isLoading || _isUploading) ? null : () {
                      setState(() {
                        _image = null;
                      });
                    },
                  ),
              ],
            ),

            SizedBox(height: 16),

            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Uploading image: ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 8),
            ],

            if (_image != null && !_isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}