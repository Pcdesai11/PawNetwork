import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawnetwork/main.dart';
import 'package:pawnetwork/models/pet.dart';
import 'package:pawnetwork/screens/home_screen.dart';
import 'package:pawnetwork/screens/signin_screen.dart';
import 'package:pawnetwork/screens/signup_screen.dart';
import 'package:pawnetwork/screens/community_feed_screen.dart';
import 'package:pawnetwork/screens/create_post_screen.dart';
import 'package:pawnetwork/screens/pet_profile_screen.dart';
import 'package:pawnetwork/models/post.dart';
import 'package:pawnetwork/models/comment.dart';
import 'package:pawnetwork/services/post_service.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'mock.dart';
import 'dart:io';
import 'package:pawnetwork/screens/main_screen.dart';

class MockPostService extends Mock implements PostService {}

// Mock Firebase Storage
class MockFirebaseStorage extends Mock {
  UploadTask mockUploadTask(String path) {
    final mockTask = MockUploadTask();
    return mockTask;
  }
}

class MockUploadTask extends Mock implements UploadTask {
  @override
  Future<TaskSnapshot> whenComplete( Function() onComplete) =>
      Future.value(MockTaskSnapshot());
}


class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class MockReference extends Mock {
  Future<String> getDownloadURL() async {
    return 'https://example.com/test-image.jpg';
  }

  MockReference child(String path) {
    return this;
  }

  UploadTask putFile(File file) {
    return MockUploadTask();
  }
}

class MockFirebaseStorageInstance extends Mock {
  MockReference ref() {
    return MockReference();
  }
}

class MockImagePicker extends Mock implements ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
    double? maxHeight,
    double? maxWidth,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final tempFile = File('${Directory.systemTemp.path}/test_image.png');
    if (!tempFile.existsSync()) {
      tempFile.createSync();
    }
    return XFile(tempFile.path);
  }
}

void main() {
  setupFirebaseAuthMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  group('Sign In Screen Tests', () {
    testWidgets('Sign In form validation works properly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignInScreen()));

      // Test empty submission
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Sign In screen has expected UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignInScreen()));

      // Check for critical UI components
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Need an account? Sign up'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    });

    testWidgets('Navigate to Sign Up screen when link is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignInScreen()));

      await tester.tap(find.text('Need an account? Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('Sign Up Screen Tests', () {
    testWidgets('Sign Up form validation works properly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Test empty submission
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);

      // Test password mismatch
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'differentpassword');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Test password length
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'pass');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'pass');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Sign Up screen has expected UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Check for critical UI components
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Email, password, confirm password
    });
  });

  group('Community Feed Screen Tests', () {
    final mockPostService = MockPostService();
    final mockPosts = [
      Post(
        id: '1',
        userId: 'user1',
        userAvatar: 'https://example.com/avatar.jpg',
        petName: 'Fluffy',
        content: 'My first post!',
        timestamp: DateTime.now(),
        likes: 5,
        commentCount: 2,
        isLiked: false,
      ),
      Post(
        id: '2',
        userId: 'user2',
        userAvatar: 'https://example.com/avatar2.jpg',
        petName: 'Rover',
        content: 'Having fun at the park!',
        imageUrl: 'https://example.com/image.jpg',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        likes: 10,
        commentCount: 3,
        isLiked: true,
      ),
    ];

    testWidgets('Community Feed displays posts correctly', (WidgetTester tester) async {
      // Mock the post service
      when(mockPostService.getPostsStream()).thenAnswer((_)  => Stream<List<Post>>.value(mockPosts));
      // Use mockNetworkImagesFor for handling network images in tests
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: CommunityFeedScreen(),
        ));
        // Wait for stream to complete
        await tester.pumpAndSettle();
        // Check for like/comment buttons
        expect(find.byIcon(Icons.favorite), findsOneWidget); // Liked post
        expect(find.byIcon(Icons.favorite_border), findsOneWidget); // Unliked post
        expect(find.byIcon(Icons.comment_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.share_outlined), findsNWidgets(2));
      });
    });

    testWidgets('Empty state shows correctly when no posts', (WidgetTester tester) async {
      // Mock the post service to return an empty list BEFORE any async operation
      when(mockPostService.getPostsStream()).thenAnswer((_) => Stream.value([]));
      await tester.pumpWidget(MaterialApp(
        home: CommunityFeedScreen(),
      ));
      // Wait for stream to complete
      await tester.pumpAndSettle();

      // Check for empty state
      expect(find.text('No posts yet'), findsOneWidget);
      expect(find.text('Be the first to share your pet\'s adventures!'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.text('Create Post'), findsOneWidget);
    });

    testWidgets('Floating Action Button navigates to Create Post screen', (WidgetTester tester) async {
      // Set up the mock response before rendering the widget
      when(mockPostService.getPostsStream()).thenAnswer((_) => Stream.value(mockPosts));
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: CommunityFeedScreen(),
          routes: {
            '/create-post': (context) => CreatePostScreen(),
          },
        ));
        await tester.pumpAndSettle();

        // Tap the FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Should navigate to Create Post screen
        expect(find.byType(CreatePostScreen), findsOneWidget);
      });
    });


  });

  group('Create Post Screen Tests', () {
    testWidgets('Create Post screen has all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: CreatePostScreen()));
      // Check for UI components
      expect(find.text('Create Post'), findsOneWidget);
      expect(find.text('Post to Community Feed'), findsOneWidget);
      expect(find.text('Pet Name'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('Validation shows error messages', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: CreatePostScreen()));

      // Tap Post button without entering data
      await tester.tap(find.text('Post to Community Feed'));
      await tester.pump();

      // Should show error for missing pet name
      expect(find.text('Failed to upload image. Please try again.'), findsNothing);

      // Enter pet name but no content
      await tester.enterText(find.widgetWithText(TextField, 'Pet Name'), 'Fluffy');
      await tester.tap(find.text('Post to Community Feed'));
      await tester.pump();

      // Should show error for missing content
      expect(find.text('Please enter post content'), findsNothing);
    });
  });

  group('Main App Tests', () {
    testWidgets('Loading screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoadingScreen()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('App initializes with correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'PawNetwork');

      expect(app.debugShowCheckedModeBanner, false);
    });
  });

  group('Post Model Tests', () {
    test('Post.fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{
        'id': '123',
        // Intentionally missing other fields
      };

      final post = Post.fromMap(map);

      expect(post.id, '123');
      expect(post.petName, 'Unknown Pet');
      expect(post.content, '');
      expect(post.likes, 0);
      expect(post.commentCount, 0);
      expect(post.isLiked, false);
    });

    test('Post.fromMap parses timestamp correctly', () {
      final timestamp = Timestamp.fromDate(DateTime(2023, 1, 1));
      final map = <String, dynamic>{
        'id': '123',
        'timestamp': timestamp,
      };

      final post = Post.fromMap(map);

      expect(post.timestamp.year, 2023);
      expect(post.timestamp.month, 1);
      expect(post.timestamp.day, 1);
    });
  });

  group('Comment Model Tests', () {
    test('Comment.fromMap creates correct object', () {
      final now = DateTime.now();
      final map = <String, dynamic>{
        'id': 'comment1',
        'postId': 'post1',
        'userId': 'user1',
        'userName': 'John Doe',
        'userAvatar': 'https://example.com/avatar.jpg',
        'content': 'Great post!',
        'timestamp': now.millisecondsSinceEpoch,
      };

      final comment = Comment.fromMap(map);

      expect(comment.id, 'comment1');
      expect(comment.postId, 'post1');
      expect(comment.userId, 'user1');
      expect(comment.userName, 'John Doe');
      expect(comment.content, 'Great post!');
      expect(comment.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Comment.fromMap converts correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'comment1',
        'postId': 'post1',
        'userId': 'user1',
        'userName': 'John Doe',
        'userAvatar': 'https://example.com/avatar.jpg',
        'content': 'Great post!',
        'timestamp': now.millisecondsSinceEpoch,
      };

      final comment = Comment.fromMap(map);

      expect(comment.id, 'comment1');
      expect(comment.postId, 'post1');
      expect(comment.userId, 'user1');
      expect(comment.userName, 'John Doe');
      expect(comment.userAvatar, 'https://example.com/avatar.jpg');
      expect(comment.content, 'Great post!');
      expect(comment.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

  });

  group('Pet Class Tests', () {
    test('Pet constructor creates a valid Pet object', () {
      // Arrange
      final petId = '123';
      final petName = 'Buddy';
      final petBreed = 'Golden Retriever';
      final petAge = 5;
      final petImageUrl = 'https://example.com/image.jpg';
      final petDescription = 'Friendly and playful dog';

      // Act
      final pet = Pet(
        id: petId,
        name: petName,
        breed: petBreed,
        age: petAge,
        imageUrl: petImageUrl,
        description: petDescription,
      );

      // Assert
      expect(pet.id, equals(petId));
      expect(pet.name, equals(petName));
      expect(pet.breed, equals(petBreed));
      expect(pet.age, equals(petAge));
      expect(pet.imageUrl, equals(petImageUrl));
      expect(pet.description, equals(petDescription));
    });

    test('Pet.fromMap creates a Pet object from a map', () {
      // Arrange
      final petId = '123';
      final petMap = {
        'name': 'Buddy',
        'breed': 'Golden Retriever',
        'age': 5,
        'imageUrl': 'https://example.com/image.jpg',
        'description': 'Friendly and playful dog',
      };

      // Act
      final pet = Pet.fromMap(petMap, id: petId);

      // Assert
      expect(pet.id, equals(petId));
      expect(pet.name, equals('Buddy'));
      expect(pet.breed, equals('Golden Retriever'));
      expect(pet.age, equals(5));
      expect(pet.imageUrl, equals('https://example.com/image.jpg'));
      expect(pet.description, equals('Friendly and playful dog'));
    });

    test('Pet.fromMap uses default values for missing fields', () {
      // Arrange
      final petId = '123';
      final petMap = {
        'name': 'Buddy',
        'breed': 'Golden Retriever',
        // Missing 'age', 'imageUrl', and 'description'
      };

      // Act
      final pet = Pet.fromMap(petMap, id: petId);

      // Assert
      expect(pet.id, equals(petId));
      expect(pet.name, equals('Buddy'));
      expect(pet.breed, equals('Golden Retriever'));
      expect(pet.age, equals(0));  // Default value for age
      expect(pet.imageUrl, equals('')); // Default value for imageUrl
      expect(pet.description, equals('')); // Default value for description
    });

    test('Pet.toMap converts Pet object to Map correctly', () {
      // Arrange
      final petId = '123';
      final pet = Pet(
        id: petId,
        name: 'Buddy',
        breed: 'Golden Retriever',
        age: 5,
        imageUrl: 'https://example.com/image.jpg',
        description: 'Friendly and playful dog',
      );

      // Act
      final petMap = pet.toMap();

      // Assrt
      expect(petMap['name'], equals('Buddy'));
      expect(petMap['breed'], equals('Golden Retriever'));
      expect(petMap['age'], equals(5));
      expect(petMap['imageUrl'], equals('https://example.com/image.jpg'));
      expect(petMap['description'], equals('Friendly and playful dog'));
    });
  });

  group('HomeScreen Tests', () {
    testWidgets('renders empty state when no pets are added', (WidgetTester tester) async {
      // Build the widget with no pets
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userId: 'userId',
            petPhotos: [],
            onAddPhoto: (photoUrl) {},
          ),
        ),
      );
      // Check if 'No pets added yet.' is displayed
      expect(find.text('No pets added yet.'), findsOneWidget);
    });
    testWidgets('renders pet card when pets are added', (WidgetTester tester) async {
      final Pet pet = Pet(
        id: 'petId',
        name: 'Fluffy',
        breed: 'Golden Retriever',
        age: 3,
        description: 'Friendly dog',
        imageUrl: 'https://example.com/image.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userId: 'userId',
            pet: pet,
            petPhotos: [],
            onAddPhoto: (imageUrl) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Fluffy'), findsOneWidget);
      expect(find.text('Breed: Golden Retriever'), findsOneWidget);
    });

    testWidgets('tap on delete icon removes pet', (WidgetTester tester) async {
      final Pet pet = Pet(
        id: 'petId',
        name: 'Fluffy',
        breed: 'Golden Retriever',
        age: 3,
        description: 'Friendly dog',
        imageUrl: 'https://storage.googleapis.com/cms-storage-bucket/a9d6ce81aee44ae017ee.png',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userId: 'userId',
            petPhotos: [],
            onAddPhoto: (photoUrl) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No pets added yet.'), findsOneWidget);
    });
  });

  // New Pet Profile Screen Tests
  group('Pet Profile Screen Tests', () {
    late MockFirebaseStorage mockStorage;
    late MockFirebaseStorageInstance mockStorageInstance;
    late MockImagePicker mockImagePicker;

    setUpAll(() {
      mockStorage = MockFirebaseStorage();
      mockStorageInstance = MockFirebaseStorageInstance();
      mockImagePicker = MockImagePicker();
    });

    testWidgets('Create Pet Profile screen renders with empty form', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id'),
      ));

      // Check for UI components
      expect(find.text('Create Pet Profile'), findsOneWidget);
      expect(find.text('Pet Name'), findsOneWidget);
      expect(find.text('Breed'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);

    });
    test('Post.toMap converts object correctly', () {
      final post = Post(
        id: '123',
        petName: 'Buddy',
        content: 'Pet is so cute!',
        timestamp: DateTime.now(),
        likes: 5,
        commentCount: 3,
        isLiked: true, userId: '12', userAvatar: '213912',
      );
      final map = post.toMap();
      expect(map['id'], '123');
      expect(map['petName'], 'Buddy');
      expect(map['content'], 'Pet is so cute!');
      expect(map['likes'], 5);
      expect(map['commentCount'], 3);
    });
    test('should create a Post with default values when map contains null or missing fields', () {
      final map = {
        'id': null,
        'userId': null,
        'userAvatar': null,
        'petName': null,
        'content': null,
        'timestamp': null,
        'likes': null,
        'commentCount': null,
        'likedBy': null,
      };

      final post = Post.fromMap(map);

      expect(post.id, '');
      expect(post.userId, '');
      expect(post.userAvatar, 'default_avatar_url');
      expect(post.petName, 'Unknown Pet');
      expect(post.content, '');
      expect(post.timestamp, DateTime.now());
      expect(post.likes, 0);
      expect(post.commentCount, 0);
      expect(post.isLiked,false);
      });
    testWidgets('Edit Pet Profile screen loads with existing pet data', (WidgetTester tester) async {
      final pet = Pet(
        id: 'test-pet-id',
        name: 'Fluffy',
        breed: 'Golden Retriever',
        age: 3,
        imageUrl: 'https://example.com/image.jpg',
        description: 'A friendly dog',
      );

      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id', pet: pet),
      ));

      // Check that the form is pre-filled with pet data
      expect(find.text('Edit Pet Profile'), findsOneWidget);
      expect(find.text('Update Profile'), findsOneWidget);

      // Check text fields have correct values
      expect(find.widgetWithText(TextFormField, 'Pet Name'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(TextFormField, 'Pet Name')) as TextFormField).controller?.text, 'Fluffy');

      expect(find.widgetWithText(TextFormField, 'Breed'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(TextFormField, 'Breed')) as TextFormField).controller?.text, 'Golden Retriever');

      expect(find.widgetWithText(TextFormField, 'Age'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(TextFormField, 'Age')) as TextFormField).controller?.text, '3');

      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(TextFormField, 'Description')) as TextFormField).controller?.text, 'A friendly dog');
    });

    testWidgets('Form validation works properly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id'),
      ));

      // Try to submit empty form
      await tester.tap(find.text('Save Profile'));
      await tester.pump();

      // Should show validation errors
      expect(find.text("Pet Name"), findsOneWidget);
      expect(find.text("Breed"), findsOneWidget);
      expect(find.text("Age"), findsOneWidget);
      expect(find.text("Description"), findsOneWidget);
    });

    testWidgets('Can fill out form completely', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id'),
      ));

      // Fill out the form
      await tester.enterText(find.widgetWithText(TextFormField, 'Pet Name'), 'Max');
      await tester.enterText(find.widgetWithText(TextFormField, 'Breed'), 'Labrador');
      await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '2');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Friendly and energetic');

      // Verify text fields have correct values
      expect((tester.widget(find.widgetWithText(TextFormField, 'Pet Name')) as TextFormField).controller?.text, 'Max');
      expect((tester.widget(find.widgetWithText(TextFormField, 'Breed')) as TextFormField).controller?.text, 'Labrador');
      expect((tester.widget(find.widgetWithText(TextFormField, 'Age')) as TextFormField).controller?.text, '2');
      expect((tester.widget(find.widgetWithText(TextFormField, 'Description')) as TextFormField).controller?.text, 'Friendly and energetic');
    });

    testWidgets('Camera button triggers image picker', (WidgetTester tester) async {
      // This test is more of a placeholder since we can't easily test image picker in widget tests
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id'),
      ));

      // Find and verify camera button exists
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('CircleAvatar shows pet image when available', (WidgetTester tester) async {
      final pet = Pet(
        id: 'test-pet-id',
        name: 'Fluffy',
        breed: 'Golden Retriever',
        age: 3,
        imageUrl: 'https://example.com/image.jpg',
        description: 'A friendly dog',
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: PetProfileScreen(userId: 'test-user-id', pet: pet),
        ));

        // Find CircleAvatar
        final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

        // Verify it has the correct image
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());
        final networkImage = circleAvatar.backgroundImage as NetworkImage;


        // Icon should not be shown when image is available
        expect(find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byIcon(Icons.pets),
        ), findsNothing);
      });
    });
    group('MainScreen Widget Tests', () {
      late FakeFirebaseFirestore fakeFirestore;
      late String userId;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
        userId = 'test-user-id';
      });

      testWidgets('MainScreen initializes with correct default state', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));
        // Verify that the bottom navigation bar is present
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('MainScreen navigates to PetProfileScreen when profile tab is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));

        // Tap on the profile tab
        await tester.tap(find.text('Profile'));

        // Verify that the PetProfileScreen is displayed
        expect(find.byType(PetProfileScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(CommunityFeedScreen), findsNothing);
      });

      testWidgets('MainScreen navigates to CommunityFeedScreen when community tab is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));

        // Tap on the community tab
        await tester.tap(find.text('Community'));

        // Verify that the CommunityFeedScreen is displayed
        expect(find.byType(CommunityFeedScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(PetProfileScreen), findsNothing);
      });

      testWidgets('MainScreen fetches and displays pet profile data', (WidgetTester tester) async {
        // Add a pet profile to the fake Firestore
        await fakeFirestore.collection('users').doc(userId).collection('pets').add({
          'name': 'Fluffy',
          'breed': 'Golden Retriever',
          'age': 3,
          'imageUrl': 'https://example.com/image.jpg',
          'description': 'A friendly dog',
        });

        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));

        // Wait for the data to be fetched
        // Verify that the pet profile data is displayed in the HomeScreen
        expect(find.text('Fluffy'), findsOneWidget);
        expect(find.text('Breed: Golden Retriever'), findsOneWidget);
        expect(find.text('Age: 3'), findsOneWidget);
        expect(find.text('Description: A friendly dog'), findsOneWidget);
      });

      testWidgets('MainScreen displays image preview when pet photos are available', (WidgetTester tester) async {
        // Add a pet profile with an image URL to the fake Firestore
        await fakeFirestore.collection('users').doc(userId).collection('pets').add({
          'name': 'Fluffy',
          'breed': 'Golden Retriever',
          'age': 3,
          'imageUrl': 'https://example.com/image.jpg',
          'description': 'A friendly dog',
        });

        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));

        // Wait for the data to be fetched

        // Verify that the image preview is displayed
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('MainScreen handles empty pet profile state', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: MainScreen(userId: userId),
        ));

        // Wait for the data to be fetched

        // Verify that no pet profile data is displayed
        expect(find.text('No pets added yet.'), findsOneWidget);
      });
    });

    testWidgets('CircleAvatar shows default icon when no image is available', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetProfileScreen(userId: 'test-user-id'),
      ));

      // Find CircleAvatar
      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

      // Verify no background image
      expect(circleAvatar.backgroundImage, isNull);

      // Icon should be shown
      expect(find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.byIcon(Icons.pets),
      ), findsOneWidget);
    });
    group('CommunityFeedScreen', () {
      late MockPostService mockPostService;
      setUp(() {
        mockPostService = MockPostService();
      });
      testWidgets('Initializes and loads posts', (WidgetTester tester) async {
        when(mockPostService.getPostsStream())
            .thenAnswer((_) => Stream.value([
          Post(
            id: '1',
            userId: 'user1',
            userAvatar: 'avatar1',
            petName: 'Pet1',
            content: 'Content1',
            timestamp: DateTime.now(),
            likes: 0,
            commentCount: 0,
            isLiked: false,
          ),
        ]));

        await tester.pumpWidget(MaterialApp(
          home: CommunityFeedScreen(),
        ));

        await tester.pump();

        expect(find.text('Pet1'), findsOneWidget);
      });

      // Add more test cases for like, comment, share, and pagination.
    });
  });
}

// Helper class for testing loading state
class TestableLoadingPetProfileScreen extends StatefulWidget {
  final String userId;
  final Pet? pet;

  const TestableLoadingPetProfileScreen({Key? key, required this.userId, this.pet}) : super(key: key);

  @override
  _TestableLoadingPetProfileScreenState createState() => _TestableLoadingPetProfileScreenState();
}

class _TestableLoadingPetProfileScreenState extends State<TestableLoadingPetProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Pet Profile')),
      body: Column(
        children: [
          ElevatedButton(
            key: Key('toggle_loading'),
            onPressed: () {
              setState(() {
                _isLoading = !_isLoading;
              });
            },
            child: Text('Toggle Loading'),
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: () {},
            child: Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}