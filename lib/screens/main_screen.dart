import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<String> petPhotos = []; // Store pet photo URLs

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchPetProfile();
  }

  // Build screens with the latest data
  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        userId: widget.userId,
        pet: currentPet,
        petPhotos: petPhotos,
        onAddPhoto: _handleAddPhoto,
      ),
      PetProfileScreen(userId: widget.userId, pet: currentPet),
      CommunityFeedScreen(),
    ];
  }

  Future<void> _fetchPetProfile() async {
    try {
      final petSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets')
          .get();

      if (petSnapshot.docs.isNotEmpty) {
        final doc = petSnapshot.docs.first;
        final petData = doc.data();

        setState(() {
          currentPet = Pet.fromMap(petData, id: doc.id);
          petPhotos = [];

          // Add pet's main image if it exists
          if (currentPet?.imageUrl.isNotEmpty ?? false) {
            petPhotos.add(currentPet!.imageUrl);
          }

          // Build screens with updated data
          _screens = _buildScreens();
        });
      } else {
        // Initialize screens even if no pet data is found
        setState(() {
          _screens = _buildScreens();
        });
      }
    } catch (e) {
      print('Error fetching pet profile: $e');
      // Initialize screens on error
      setState(() {
        _screens = _buildScreens();
      });
    }
  }

  // Handle adding a new photo
  Future<void> _handleAddPhoto(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      setState(() {
        petPhotos.add(imageUrl);
        // Rebuild screens with updated images
        _screens = _buildScreens();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens != null && _selectedIndex < _screens.length
          ? _screens[_selectedIndex]
          : Center(child: CircularProgressIndicator()),
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