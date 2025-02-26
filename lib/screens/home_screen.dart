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
import 'package:image_picker_for_web/image_picker_for_web.dart';

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
  List<String> petPhotos = []; // List to store pet image URLs

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

  Future<void> _deletePetProfile(String petId) async {
    try {
      // Delete the pet profile from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets')
          .doc(petId)
          .delete();

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
    } catch (e) {
      print('Error getting download URL: $e');
    }
  }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated");
      return;
    }
    String userId = user.uid;
    print(userId);
    String imageId = path.basename(pickedFile!.path);
    print(imageId);
    if (pickedFile == null) return;
    try {
      Reference storageRef = FirebaseStorage.instance.ref().child('pets/$userId/$imageId');
      UploadTask uploadTask;
      if (kIsWeb) {
        // Web platform - handle image upload using bytes
        Uint8List imageData = await pickedFile.readAsBytes();
        uploadTask = storageRef.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Mobile platform - handle image upload from file
        File imageFile = File(pickedFile.path);
        uploadTask = storageRef.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      }
      // Handle the upload task and get the download URL
      await _handleUpload(uploadTask, storageRef);
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image!")),
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
        onPressed: uploadImage,
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No pets added yet.'),
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePetProfile(pet.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
