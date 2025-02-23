import 'package:flutter/material.dart';
import '../../models/pet.dart';

class PetProfileScreen extends StatefulWidget {
  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final String _pugImageUrl = 'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg';
  bool _useDefaultImage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Pet Profile'),
        backgroundColor: Colors.pinkAccent, // Pet-friendly color
      ),
      body: Stack(
        children: [
          // Full-screen background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE4E1), Color(0xFFFACDCE)], // Soft pastel pinks for pet theme
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: DecorationImage(
                  image: AssetImage('assets/paw_background.png'), // Optional: Paw print background
                  fit: BoxFit.cover,
                  opacity: 0.1,
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
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            image: _useDefaultImage
                                ? DecorationImage(
                              image: NetworkImage(_pugImageUrl),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: !_useDefaultImage
                              ? Icon(Icons.pets, size: 50, color: Colors.grey[400])
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: FloatingActionButton(
                            backgroundColor: Colors.pinkAccent,
                            onPressed: () {
                              setState(() {
                                _useDefaultImage = !_useDefaultImage;
                              });
                            },
                            child: Icon(
                              _useDefaultImage ? Icons.refresh : Icons.camera_alt,
                              size: 20,
                            ),
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
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _savePetProfile,
                      child: Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your pet\'s $label';
          }
          return null;
        },
      ),
    );
  }

  void _savePetProfile() {
    if (_formKey.currentState!.validate()) {
      final pet = Pet(
        name: _nameController.text,
        breed: _breedController.text,
        age: int.parse(_ageController.text),
        imageUrl: _useDefaultImage ? _pugImageUrl : '',
        description: _descriptionController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet profile saved successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/community-feed');
    }
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
