import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:pawnetwork/main.dart';
import 'package:pawnetwork/models/pet.dart';
import 'package:pawnetwork/models/post.dart';
import 'package:pawnetwork/screens/community_feed_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawnetwork/screens/main_screen.dart';
import 'package:pawnetwork/screens/pet_profile_screen.dart';
import 'package:pawnetwork/screens/signin_screen.dart';
import 'package:pawnetwork/screens/signup_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

class MockFirebaseApp extends Mock implements FirebaseApp
{
  @override
  final String name = 'mock_app';

  @override
  final FirebaseOptions options = const FirebaseOptions(
    apiKey: 'mock_api_key',
    appId: 'mock_app_id',
    messagingSenderId: 'mock_messaging_sender_id',
    projectId: 'mock_project_id',
  );
  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  bool get isAutomaticResourceManagementEnabled => false;
}

void main() {
  setUpAll(() => HttpOverrides.global = null);
  late MockFirebaseAuth mockFirebaseAuth;
  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
  });


  group('Pet Model Tests', () {
    test('Should create a Pet object correctly', () {
      final pet = Pet(
        name: 'Buddy',
        breed: 'Golden Retriever',
        age: 3,
        imageUrl: 'https://example.com/buddy.jpg',
        description: 'A friendly dog',
      );

      expect(pet.name, 'Buddy');
      expect(pet.breed, 'Golden Retriever');
      expect(pet.age, 3);
      expect(pet.imageUrl, 'https://example.com/buddy.jpg');
      expect(pet.description, 'A friendly dog');
    });

    test('Should convert Pet object to map correctly', () {
      final pet = Pet(
        name: 'Buddy',
        breed: 'Golden Retriever',
        age: 3,
        imageUrl: 'https://example.com/buddy.jpg',
        description: 'A friendly dog',
      );

      final petMap = pet.toMap();

      expect(petMap, {
        'name': 'Buddy',
        'breed': 'Golden Retriever',
        'age': 3,
        'imageUrl': 'https://example.com/buddy.jpg',
        'description': 'A friendly dog',
      });
    });

    test('Should create Pet object from map correctly', () {
      final petMap = {
        'name': 'Buddy',
        'breed': 'Golden Retriever',
        'age': 3,
        'imageUrl': 'https://example.com/buddy.jpg',
        'description': 'A friendly dog',
      };

      final pet = Pet.fromMap(petMap);

      expect(pet.name, 'Buddy');
      expect(pet.breed, 'Golden Retriever');
      expect(pet.age, 3);
      expect(pet.imageUrl, 'https://example.com/buddy.jpg');
      expect(pet.description, 'A friendly dog');
    });

    test('Should handle missing values in fromMap gracefully', () {
      final petMap = {
        'name': 'Unknown',
      };

      final pet = Pet.fromMap(petMap);

      expect(pet.name, 'Unknown');
      expect(pet.breed, ''); // Default empty string
      expect(pet.age, 0); // Default age is 0
      expect(pet.imageUrl, ''); // Default empty string
      expect(pet.description, ''); // Default empty string
    });
  });
  group('Post Model Tests', () {
    test('Should create a Post object correctly', () {
      final post = Post(
        userId: 'user123',
        petName: 'Buddy',
        content: 'Had a fun day at the park!',
        imageUrl: 'https://example.com/buddy_park.jpg',
        timestamp: DateTime.parse('2025-02-06T12:00:00Z'),
        likes: 100,
      );

      expect(post.userId, 'user123');
      expect(post.petName, 'Buddy');
      expect(post.content, 'Had a fun day at the park!');
      expect(post.imageUrl, 'https://example.com/buddy_park.jpg');
      expect(post.timestamp, DateTime.parse('2025-02-06T12:00:00Z'));
      expect(post.likes, 100);
    });

    test('Should convert Post object to map correctly', () {
      final post = Post(
        userId: 'user123',
        petName: 'Buddy',
        content: 'Had a fun day at the park!',
        imageUrl: 'https://example.com/buddy_park.jpg',
        timestamp: DateTime.parse('2025-02-06T12:00:00Z'),
        likes: 100,
      );

      final postMap = post.toMap();

      expect(postMap, {
        'userId': 'user123',
        'petName': 'Buddy',
        'content': 'Had a fun day at the park!',
        'imageUrl': 'https://example.com/buddy_park.jpg',
        'timestamp': '2025-02-06T12:00:00.000Z',
        'likes': 100,
      });
    });

    test('Should create Post object from map correctly', () {
      final postMap = {
        'userId': 'user123',
        'petName': 'Buddy',
        'content': 'Had a fun day at the park!',
        'imageUrl': 'https://example.com/buddy_park.jpg',
        'timestamp': '2025-02-06T12:00:00.000Z',
        'likes': 100,
      };

      final post = Post.fromMap(postMap);

      expect(post.userId, 'user123');
      expect(post.petName, 'Buddy');
      expect(post.content, 'Had a fun day at the park!');
      expect(post.imageUrl, 'https://example.com/buddy_park.jpg');
      expect(post.timestamp, DateTime.parse('2025-02-06T12:00:00.000Z'));
      expect(post.likes, 100);
    });

    test('Should handle missing or null values in fromMap gracefully', () {
      final postMap = {
        'userId': 'user123',
        'petName': 'Buddy',
        'content': 'Had a fun day at the park!',
        'timestamp': '2025-02-06T12:00:00.000Z',
        'likes': 100,
      };

      final post = Post.fromMap(postMap);

      expect(post.userId, 'user123');
      expect(post.petName, 'Buddy');
      expect(post.content, 'Had a fun day at the park!');
      expect(post.imageUrl, null); // imageUrl should be null
      expect(post.timestamp, DateTime.parse('2025-02-06T12:00:00.000Z'));
      expect(post.likes, 100);
    });
  });
  group('CommunityFeedScreen Tests', () {
    testWidgets('Should display AppBar with title', (tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(MaterialApp(
        home: CommunityFeedScreen(),
      ));
      await tester.pumpAndSettle();
      // Assert: Check for the AppBar title
      expect(find.text('PawNetwork Feed'), findsOneWidget);
    });

    testWidgets('Should display list of posts', (tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(MaterialApp(
        home: CommunityFeedScreen(),
      ));
      await tester.pumpAndSettle();
      // Assert: Check that the list of posts is displayed
      expect(find.byType(Card), findsNWidgets(2)); // Expect 2 posts
    });

    testWidgets('Should show like button and display likes', (tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(MaterialApp(
        home: CommunityFeedScreen(),
      ));
      await tester.pumpAndSettle();
      // Assert: Check if like button is displayed and likes are shown
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(2)); // Expect 2 like buttons
      expect(find.text('15'), findsOneWidget); // Check if likes are displayed for the first post
      expect(find.text('24'), findsOneWidget); // Check if likes are displayed for the second post
    });

    testWidgets('Should show RefreshIndicator', (tester) async {
      // Arrange: Build the screen
      await tester.pumpWidget(MaterialApp(
        home: CommunityFeedScreen(),
      ));
      await tester.pumpAndSettle();
      // Assert: Check that the RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
  group('MainScreen Tests', () {
    testWidgets('Should display BottomNavigationBar with correct items', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('Should switch screens when tapping BottomNavigationBar items', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Community'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(find.text('Add Pet'), findsOneWidget);
    });
  });
  group('PetProfileScreen Tests', () {
    testWidgets('Should display form fields and save button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PetProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Breed, Age, Description
      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('Should toggle default image when refresh button is clicked', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PetProfileScreen()));
      await tester.pumpAndSettle();

      final Finder refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Image toggled
    });

    testWidgets('renders pet profile form', (WidgetTester tester) async {
      // Build the PetProfileScreen widget.
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(),
      ));
      await tester.pumpAndSettle();
      // Check if the form fields and buttons are rendered.
      expect(find.text('Create Pet Profile'), findsOneWidget);
      expect(find.text('Pet Name'), findsOneWidget);
      expect(find.text('Breed'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

  });
  group('App Widget Tests', () {
    testWidgets('App initializes and shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('App shows error when Firebase initialization fails', (WidgetTester tester) async {
      // Mock Firebase initialization to throw an error
      final mockFirebaseApp = MockFirebaseApp();
      when(() => Firebase.initializeApp()).thenThrow(Exception('Initialization failed'));
      await tester.pumpWidget(MyApp());
      await tester.pump();
      // Expecting the error message on the screen
      expect(find.text('Error: Exception: Initialization failed'), findsOneWidget);
    });

    testWidgets('App shows MyApp when Firebase initialization is done', (WidgetTester tester) async {
      // Mock Firebase initialization to complete successfully
      when(() => Firebase.initializeApp()).thenAnswer((_) async => MockFirebaseApp());

      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(MyApp), findsOneWidget);
    });
  });
  group('MyApp Widget Tests', () {
    testWidgets('MyApp shows SignInScreen when user is not authenticated', (WidgetTester tester) async {
      // Mock FirebaseAuth to return null user
      when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('MyApp shows MainScreen when user is authenticated', (WidgetTester tester) async {
      // Mock FirebaseAuth to return a user
      final mockUser = MockUser(isAnonymous: false, uid: '123');
      when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

      await tester.pumpWidget(
        MaterialApp(
          home: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('MyApp navigates to SignInScreen when user logs out', (WidgetTester tester) async {
      // Mock FirebaseAuth to return a user initially and then null after logout
      final mockUser = MockUser(isAnonymous: false, uid: '123');
      when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate logout
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });
}
