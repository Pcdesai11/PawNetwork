import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pet.dart';
import 'home_screen.dart';
import 'pet_profile_screen.dart';
import 'community_feed_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Pet? currentPet;
  List<String> petPhotos = []; // Store pet photos here

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = _buildScreens();
    _fetchPetProfile();
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        userId: widget.userId,
        pet: currentPet,
        petPhotos: petPhotos, // Ensure updated images are passed
        onAddPhoto: _handleAddPhoto,
      ),
      PetProfileScreen(userId: widget.userId, pet: currentPet),
      CommunityFeedScreen(),
    ];
  }

  Future<void> _fetchPetProfile() async {
    final petSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('pets')
        .get();

    if (petSnapshot.docs.isNotEmpty) {
      final doc = petSnapshot.docs.first; // Get the first document
      final petData = doc.data(); // Get the data from the document
      setState(() {
        currentPet = Pet.fromMap(petData, id: doc.id); // Pass the document ID
        if (currentPet?.imageUrl.isNotEmpty ?? false) {
          petPhotos.add(currentPet!.imageUrl);
        }
        _screens = _buildScreens(); // Rebuild screens with updated data
      });
    }
  }

  Future<void> _handleAddPhoto(String imageUrl) async {
    setState(() {
      _screens = _buildScreens(); // Rebuild screens with updated images
    });
    print("photo url: ${petPhotos[0]}");
    print("passed from handle photo");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Screen')),
      body: Column(
        children: [
          if (petPhotos.isNotEmpty) // Show images if available
            SizedBox(
              height: 150, // Set height for image preview
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: petPhotos.length,
                itemBuilder: (context, index)
                {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.network(
                        petPhotos[index],
                        height: 150,
                        width: 100,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
                        File(petPhotos[index]),
                        height: 150,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(child: _screens[_selectedIndex]), // Show selected screen
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ],
      ),
    );
  }
}