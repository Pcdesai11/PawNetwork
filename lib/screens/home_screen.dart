import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet.dart';

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
        onPressed: () {
          if (widget.onAddPhoto != null) {
            widget.onAddPhoto!('new_image_url');
          }
        },
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