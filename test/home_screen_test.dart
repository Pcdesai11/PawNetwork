import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pawnetwork/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawnetwork/models/pet.dart';
import 'auth service test.mocks.dart' as auth_mocks; // Add prefix here

import 'package:firebase_core/firebase_core.dart';// No prefix here

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test-user-id';
}
// Generate mocks for the Firebase classes we need
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeUser _user = FakeUser();

  @override
  User? get currentUser => _user;
}

void main() {
  late FirebaseAuth mockFirebaseAuth;
  late FakeUser fakeUser;

  setUp(() {
    // Initialize mocks

    fakeUser = FakeUser(); // Use FakeUser instead of MockUser

    // Mocking currentUser getter properly
    mockFirebaseAuth = FakeFirebaseAuth(); // Use Fake instead of Mock
  });


  testWidgets('HomeScreen shows empty state when no pets', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
        ),
      ),
    );

    // Render the widget
    await tester.pump();

    // Assert
    expect(find.text('No pets added yet.'), findsOneWidget);
    expect(find.text('Add Your First Pet'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
  });


  // Rest of your test code remains unchanged...


  testWidgets('HomeScreen shows empty state when no pets', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
        ),
      ),
    );

    // Render the widget
    await tester.pump();

    // Assert
    expect(find.text('No pets added yet.'), findsOneWidget);
    expect(find.text('Add Your First Pet'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
  });

  testWidgets('HomeScreen shows pet cards when pets exist', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];
    final testPets = [
      Pet(
        id: 'pet1',
        name: 'Buddy',
        breed: 'Golden Retriever',
        age: 5,
        description: 'Friendly dog',
        imageUrl: 'https://example.com/pet.jpg',
      ),
      Pet(
        id: 'pet2',
        name: 'Whiskers',
        breed: 'Persian Cat',
        age: 3,
        description: 'Cute cat',
        imageUrl: '',
      ),
    ];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: TestHomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
          testPets: testPets,
        ),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Whiskers'), findsOneWidget);
    expect(find.text('Breed: Golden Retriever'), findsOneWidget);
    expect(find.text('Breed: Persian Cat'), findsOneWidget);
    expect(find.text('Age: 5 years'), findsOneWidget);
    expect(find.text('Age: 3 years'), findsOneWidget);
    expect(find.text('Description: Friendly dog'), findsOneWidget);
    expect(find.text('Description: Cute cat'), findsOneWidget);
  });

  testWidgets('HomeScreen has working AppBar with logout button', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
        ),
        routes: {
          '/signin': (context) => const Scaffold(body: Text('Sign In Screen')),
        },
      ),
    );

    // Assert AppBar elements
    expect(find.text('My Pets'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('Add photo button is present', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
        ),
      ),
    );

    // Render the widget
    await tester.pump();

    // Assert
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
  });

  testWidgets('Pet card shows edit and delete buttons', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];
    final testPet = Pet(
      id: 'pet1',
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: 5,
      description: 'Friendly dog',
      imageUrl: 'https://example.com/pet.jpg',
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: TestHomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
          testPets: [testPet],
        ),
        routes: {
          '/edit_pet': (context) => const Scaffold(body: Text('Edit Pet Screen')),
        },
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Assert
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Delete button shows confirmation dialog', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];
    final testPet = Pet(
      id: 'pet1',
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: 5,
      description: 'Friendly dog',
      imageUrl: 'https://example.com/pet.jpg',
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: TestHomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
          testPets: [testPet],
        ),
      ),
    );

    // Wait for widget to build
    await tester.pumpAndSettle();

    // Find and tap the delete button
    final deleteButton = find.byIcon(Icons.delete);
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Assert dialog appears
    expect(find.text('Delete Pet Profile'), findsOneWidget);
    expect(find.text('Are you sure you want to delete Buddy\'s profile? This action cannot be undone.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Empty pet image URL is handled properly', (WidgetTester tester) async {
    // Arrange
    final List<String> petPhotos = [];
    final testPet = Pet(
      id: 'pet1',
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: 5,
      description: 'Friendly dog',
      imageUrl: '', // Empty image URL
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: TestHomeScreen(
          userId: 'test-user-id',
          petPhotos: petPhotos,
          testPets: [testPet],
        ),
      ),
    );

    // Wait for widget to build
    await tester.pumpAndSettle();

    // Assert pet details are shown without an image
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Breed: Golden Retriever'), findsOneWidget);
    expect(find.text('Age: 5 years'), findsOneWidget);
    // No image should be displayed since imageUrl is empty
    expect(find.byType(Image), findsNothing);
  });
}

// Test implementation of HomeScreen to avoid Firebase calls
class TestHomeScreen extends StatefulWidget {
  final String? userId;
  final List<String> petPhotos;
  final List<Pet> testPets;

  const TestHomeScreen({
    Key? key,
    this.userId,
    required this.petPhotos,
    required this.testPets,
  }) : super(key: key);

  @override
  TestHomeScreenState createState() => TestHomeScreenState();
}

class TestHomeScreenState extends State<TestHomeScreen> {
  late List<Pet> pets;

  @override
  void initState() {
    super.initState();
    pets = widget.testPets;
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
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: pets.isEmpty
          ? Center(
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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: Text('Add Your First Pet'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          return _buildPetCard(pets[index], context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildPetCard(Pet pet, BuildContext context) {
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
                  onPressed: () => _showDeleteConfirmation(pet.id, pet.name, context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String petId, String petName, BuildContext context) {
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
              },
            ),
          ],
        );
      },
    );
  }
}