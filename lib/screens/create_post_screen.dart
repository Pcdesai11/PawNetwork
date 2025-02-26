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

  File? _image;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      final fileName = path.basename(_image!.path);
      final destination = 'post_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final ref = FirebaseStorage.instance.ref().child(destination);
      final uploadTask = ref.putFile(_image!);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _errorMessage = 'Failed to upload image. Please try again.';
      });
      return null;
    }
  }

  Future<void> _createPost() async {
    if (_petNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your pet name';
      });
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter post content';
      });
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
      }

      await _postService.createPost(
        petName: _petNameController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create post: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          _isLoading
              ? Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
              : TextButton(
            onPressed: _createPost,
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

            TextField(
              controller: _petNameController,
              decoration: InputDecoration(
                labelText: 'Pet Name',
                hintText: 'Enter your pet\'s name',
              ),
            ),

            SizedBox(height: 16),

            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'What\'s on your pet\'s mind?',
                alignLabelWithHint: true,
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: Icon(Icons.photo),
              label: Text('Add Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),

            SizedBox(height: 16),

            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _image = null;
                  });
                },
                icon: Icon(Icons.delete),
                label: Text('Remove Photo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
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