import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pet.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final Pet? pet;
  final List<String> petPhotos;
  final Function(String)? onAddPhoto;

  const HomeScreen({
    Key? key,
    this.userId,
    this.pet,
    required this.petPhotos,
    this.onAddPhoto,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pet> pets = []; // List to store pet details

  @override
  void initState() {
    super.initState();
    _loadPetProfile();
  }

  Future<void> _loadPetProfile() async {
    if (widget.userId == null) return;

    final petSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('pets')
        .get();

    if (petSnapshot.docs.isNotEmpty) {
      setState(() {
        pets = petSnapshot.docs.map((doc) {
          return Pet.fromMap(doc.data(), id: doc.id); // Pass the document ID
        }).toList();
      });
    }
  }

  // Fixed to delete associated images from Firebase Storage
  Future<void> _deletePetProfile(String petId) async {
    try {
      // Get the pet to access its imageUrl
      Pet? petToDelete = pets.firstWhere((pet) => pet.id == petId);

      // Delete the pet profile from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets')
          .doc(petId)
          .delete();

      // Delete the associated image from Firebase Storage if it exists
      if (petToDelete.imageUrl.isNotEmpty) {
        try {
          // Extract the storage path from the download URL
          Reference imageRef = FirebaseStorage.instance.refFromURL(petToDelete.imageUrl);
          await imageRef.delete();
        } catch (storageError) {
          print('Error deleting image: $storageError');
          // Continue with deletion even if image deletion fails
        }
      }

      // Immediately remove the deleted pet from the local list
      setState(() {
        pets.removeWhere((pet) => pet.id == petId);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pet profile deleted!'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUpload(UploadTask uploadTask, Reference storageRef) async {
    try {
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        // Add the uploaded image URL to the pet photos list
        widget.petPhotos.add(downloadUrl);
      });
      // Optionally, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image uploaded successfully!")),
      );

      // Call the callback to notify parent widget
      if (widget.onAddPhoto != null) {
        widget.onAddPhoto!(downloadUrl);
      }
    } catch (e) {
      print('Error getting download URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to process uploaded image!"), backgroundColor: Colors.red),
      );
    }
  }

  // Fixed path and added permission handling
  Future<void> uploadImage() async {
    // Check for permissions on mobile platforms
    if (!kIsWeb) {
      var status = await Permission.photos.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gallery access permission denied"), backgroundColor: Colors.red),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gallery access permanently denied. Please enable in settings."),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not authenticated"), backgroundColor: Colors.red),
        );
        return;
      }

      String userId = user.uid;
      String imageId = DateTime.now().millisecondsSinceEpoch.toString(); // Unique ID instead of file path

      // Consistent path for pet images: users/{userId}/pets/images/{imageId}
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users/$userId/pets/images/$imageId');

      UploadTask uploadTask;
      if (kIsWeb) {
        // Web platform - handle image upload using bytes
        Uint8List imageData = await pickedFile.readAsBytes();
        uploadTask = storageRef.putData(
            imageData,
            SettableMetadata(contentType: 'image/jpeg')
        );
      } else {
        // Mobile platform - handle image upload from file
        File imageFile = File(pickedFile.path);
        uploadTask = storageRef.putFile(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg')
        );
      }

      // Handle the upload task and get the download URL
      await _handleUpload(uploadTask, storageRef);
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pets'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: pets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          return _buildPetCard(pets[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => uploadImage(),
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No pets added yet.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add_pet');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: Text('Add Your First Pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pet.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pet.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 12),
            Text(
              pet.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Breed: ${pet.breed}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Age: ${pet.age} years',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Description: ${pet.description}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/edit_pet',
                      arguments: pet,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(pet.id, pet.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String petId, String petName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Pet Profile'),
          content: Text('Are you sure you want to delete $petName\'s profile? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePetProfile(petId);
              },
            ),
          ],
        );
      },
    );
  }
}