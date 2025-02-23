import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:animations/animations.dart';

class HomeScreen extends StatefulWidget {
  final Function? onAddPhoto;
  final Function(String)? addPhotoCallback;

  const HomeScreen({Key? key, this.onAddPhoto, this.addPhotoCallback}) : super(key: key);

  void addPhoto(String path) {
    if (addPhotoCallback != null) {
      addPhotoCallback!(path);
    }
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> petPhotos = [];

  void addPhoto(String path) {
    setState(() {
      petPhotos.add(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [

          Opacity(
            opacity: 0.3,
            child: Image.asset(
              'assets/paw_background.png',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Pet Photos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: petPhotos.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 100,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pet photos yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_a_photo),
                          label: Text('Add Your First Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF8E2DE2),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: widget.onAddPhoto as void Function()?,
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: petPhotos.length,
                    itemBuilder: (context, index) {
                      return OpenContainer(
                        closedElevation: 0,
                        closedBuilder: (context, openContainer) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'photo_$index',
                                child: Image.file(
                                  File(petPhotos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      petPhotos.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        openBuilder: (context, closeContainer) => Scaffold(
                          backgroundColor: Colors.black,
                          body: Center(
                            child: Hero(
                              tag: 'photo_$index',
                              child: Image.file(
                                File(petPhotos[index]),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
