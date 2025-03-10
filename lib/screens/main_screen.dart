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

  // Initialize with empty screens instead of using late
  List<Widget> _screens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPetProfile();
  }

  // Build screens with the latest data
  void _buildScreens() {
    _screens = [
      HomeScreen(
        userId: widget.userId,
        pet: currentPet,
        petPhotos: petPhotos,
        onAddPhoto: _handleAddPhoto,
      ),
      // Use a builder function for PetProfileScreen to handle navigation
      Builder(
        builder: (context) => PetProfileScreen(
          userId: widget.userId,
          pet: currentPet,
        ),
      ),
      CommunityFeedScreen(),
    ];
  }

  Future<void> _fetchPetProfile() async {
    setState(() {
      _isLoading = true;
    });

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
        });
      }
    } catch (e) {
      print('Error fetching pet profile: $e');
    } finally {
      // Build screens and set loading to false
      setState(() {
        _buildScreens();
        _isLoading = false;
      });
    }
  }

  // Handle adding a new photo
  Future<void> _handleAddPhoto(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      setState(() {
        petPhotos.add(imageUrl);
        // Rebuild screens with updated images
        _buildScreens();
      });
    }
  }

  // Handle pet profile updates
  Future<void> _navigateToPetProfile() async {
    final updatedPet = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetProfileScreen(
          userId: widget.userId,
          pet: currentPet,
        ),
      ),
    );

    // If we got an updated pet back, refresh our data
    if (updatedPet != null) {
      setState(() {
        currentPet = updatedPet;

        // Update petPhotos if the main image changed
        if (currentPet != null &&
            (petPhotos.isEmpty ||
                (petPhotos.isNotEmpty && petPhotos[0] != currentPet!.imageUrl))) {
          // Replace the first photo or add it if empty
          if (petPhotos.isEmpty) {
            petPhotos.add(currentPet!.imageUrl);
          } else {
            petPhotos[0] = currentPet!.imageUrl;
          }
        }

        // Rebuild screens with updated data
        _buildScreens();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still loading, show a loading indicator
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (_) {}, // Disable taps while loading
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            // If tapping the pet profile tab, navigate properly
            _navigateToPetProfile();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
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