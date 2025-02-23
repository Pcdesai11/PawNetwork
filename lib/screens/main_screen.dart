// main_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'pet_profile_screen.dart';
import 'community_feed_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();

  // Create instances of all screens
  late final List<Widget> _screens;
  late final HomeScreen _homeScreen;

  @override
  void initState() {
    super.initState();
    _homeScreen = HomeScreen(onAddPhoto: _handleAddPhoto);
    _screens = [
      _homeScreen,
      PetProfileScreen(),
      CommunityFeedScreen(),
    ];
  }

  Future<void> _handleAddPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        // Add the photo to home screen
        _homeScreen.addPhoto(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: _handleAddPhoto,
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF8E2DE2),
      )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Pet Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF8E2DE2),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

