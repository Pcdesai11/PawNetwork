import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../models/pet.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class PetProfileScreen extends StatefulWidget {
  final String userId;
  final Pet? pet;

  const PetProfileScreen({Key? key, required this.userId, this.pet}) : super(key: key);

  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  String _imageUrl = '';
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.pet != null) {
      _isEditing = true;
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age.toString();
      _descriptionController.text = widget.pet!.description;
      _imageUrl = widget.pet!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final fileName = path.basename(file.path);
    final directory = await getTemporaryDirectory();
    final targetPath = path.join(directory.path, fileName);

    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 60,  // Adjust quality as needed (0-100)
    );

    return result != null ? File(result.path) : file;  // Convert XFile to File
  }

  Future<void> _savePetProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _imageUrl;
      String? oldImageUrl;

      // If editing and a new image is selected, save the old URL for deletion
      if (_isEditing && _imageFile != null && _imageUrl.isNotEmpty) {
        oldImageUrl = _imageUrl;
      }

      // Upload image if a new file is selected
      if (_imageFile != null) {
        final compressedImage = await _compressImage(_imageFile!);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(compressedImage.path)}';
        final storageRef = FirebaseStorage.instance.ref().child('pet_images/$fileName');
        await storageRef.putFile(compressedImage);
        imageUrl = await storageRef.getDownloadURL();

        // Delete old image after successful upload of new one
        if (oldImageUrl != null) {
          try {
            // Extract the path from the URL
            final ref = FirebaseStorage.instance.refFromURL(oldImageUrl);
            await ref.delete();
          } catch (e) {
            print('Failed to delete old image: $e');
            // Continue execution even if deletion fails
          }
        }
      }

      final petRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets');

      Pet pet;

      if (_isEditing) {
        // Update existing pet profile
        pet = Pet(
          id: widget.pet!.id,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          imageUrl: imageUrl,
          description: _descriptionController.text.trim(),
        );

        await petRef.doc(widget.pet!.id).update(pet.toMap());

        // Show success message and ensure it's shown before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet profile updated!'),
            backgroundColor: Colors.pinkAccent,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Create new pet profile with a generated document reference
        final newDocRef = petRef.doc();  // Get a new document reference

        pet = Pet(
          id: newDocRef.id,  // Always use the new ID for new pets
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          imageUrl: imageUrl,
          description: _descriptionController.text.trim(),
        );

        // Use the same reference to set the data
        await newDocRef.set(pet.toMap());

        // Show success message and ensure it's shown before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet profile created!'),
            backgroundColor: Colors.pinkAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Delay the navigation slightly to allow the UI to update
      // and the Snackbar to be visible
      await Future.delayed(Duration(milliseconds: 500));

      // Make sure we're still mounted before trying to navigate
      if (mounted) {
        Navigator.pop(context, pet);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Only update state if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return null when navigating back to indicate no data was changed
        Navigator.pop(context, null);
        return false; // Prevents default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Pet Profile' : 'Create Pet Profile'),
          backgroundColor: Colors.pinkAccent,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Explicitly handle back navigation
              Navigator.pop(context, null);
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE4E1), Color(0xFFFACDCE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 75,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : _imageUrl.isNotEmpty
                                ? NetworkImage(_imageUrl) as ImageProvider
                                : null,
                            child: _imageFile == null && _imageUrl.isEmpty
                                ? Icon(Icons.pets, size: 50, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton(
                              backgroundColor: Colors.pinkAccent,
                              onPressed: _pickImage,
                              child: Icon(Icons.camera_alt),
                              mini: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildTextField('Pet Name', _nameController, Icons.pets),
                    SizedBox(height: 16),
                    _buildTextField('Breed', _breedController, Icons.category),
                    SizedBox(height: 16),
                    _buildTextField('Age', _ageController, Icons.cake, keyboardType: TextInputType.number),
                    SizedBox(height: 16),
                    _buildTextField('Description', _descriptionController, Icons.description, maxLines: 3),
                    SizedBox(height: 24),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _savePetProfile,
                      child: Text(
                        _isEditing ? 'Update Profile' : 'Save Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your pet\'s $label';
        }

        // Add age-specific validation
        if (label == 'Age') {
          try {
            final age = int.parse(value);
            if (age <= 0) {
              return 'Age must be a positive number';
            }
            if (age > 30) {  // Assuming 30 is a reasonable maximum age for pets
              return 'Please enter a valid age';
            }
          } catch (e) {
            return 'Please enter a valid number';
          }
        }

        return null;
      },
      enabled: !_isLoading, // Disable fields during loading
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}