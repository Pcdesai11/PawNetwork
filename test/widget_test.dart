import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pawnetwork/main.dart';
import 'package:pawnetwork/screens/signin_screen.dart';
import 'package:pawnetwork/screens/signup_screen.dart';
import 'package:pawnetwork/screens/community_feed_screen.dart';
import 'package:pawnetwork/screens/create_post_screen.dart';
import 'package:pawnetwork/models/post.dart';
import 'package:pawnetwork/models/comment.dart';
import 'package:pawnetwork/services/post_service.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'mock.dart';

class MockPostService extends Mock implements PostService {}

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
      when(mockPostService.getPostsStream()).thenAnswer((_) => Stream.value(mockPosts));

      // Use mockNetworkImagesFor for handling network images in tests
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: CommunityFeedScreen(),
        ));

        // Wait for stream to complete
        await tester.pumpAndSettle();

        // Check for post content
        expect(find.text('Fluffy'), findsOneWidget);
        expect(find.text('Rover'), findsOneWidget);
        expect(find.text('My first post!'), findsOneWidget);
        expect(find.text('Having fun at the park!'), findsOneWidget);

        // Check for like/comment buttons
        expect(find.byIcon(Icons.favorite), findsOneWidget); // Liked post
        expect(find.byIcon(Icons.favorite_border), findsOneWidget); // Unliked post
        expect(find.byIcon(Icons.comment_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.share_outlined), findsNWidgets(2));
      });
    });

    testWidgets('Empty state shows correctly when no posts', (WidgetTester tester) async {
      // Mock the post service to return empty list
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
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Pet Name'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('Validation shows error messages', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: CreatePostScreen()));

      // Tap Post button without entering data
      await tester.tap(find.text('Post'));
      await tester.pump();

      // Should show error for missing pet name
      expect(find.text('Please enter your pet name'), findsOneWidget);

      // Enter pet name but no content
      await tester.enterText(find.widgetWithText(TextField, 'Pet Name'), 'Fluffy');
      await tester.tap(find.text('Post'));
      await tester.pump();

      // Should show error for missing content
      expect(find.text('Please enter post content'), findsOneWidget);
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

    test('Comment.toMap converts correctly', () {
      final now = DateTime.now();
      final comment = Comment(
        id: 'comment1',
        postId: 'post1',
        userId: 'user1',
        userName: 'John Doe',
        userAvatar: 'https://example.com/avatar.jpg',
        content: 'Great post!',
        timestamp: now,
      );

      final map = comment.toMap();

      expect(map['id'], 'comment1');
      expect(map['postId'], 'post1');
      expect(map['userId'], 'user1');
      expect(map['userName'], 'John Doe');
      expect(map['content'], 'Great post!');
      expect(map['timestamp'], now.millisecondsSinceEpoch);
    });
  });
}