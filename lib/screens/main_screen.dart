import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
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
        petPhotos: petPhotos, // Pass the photo list
        onAddPhoto: _handleAddPhoto, // Pass the callback
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
        _screens = _buildScreens();
      });
    }
  }

  Future<void> _handleAddPhoto(String imageUrl) async {
    setState(() {
      petPhotos.add(imageUrl); // Update the photo list
    });
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Handle web-specific image picking
      print("Image picking on web is not fully supported yet.");
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _handleAddPhoto(image.path); // Use the callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.pinkAccent,
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          if (index == 1) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PetProfileScreen(userId: widget.userId, pet: currentPet),
              ),
            );
            if (result is Pet) {
              setState(() {
                currentPet = result;
                _screens = _buildScreens();
              });
            }
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pet Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ],
      ),
    );
  }
}