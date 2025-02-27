import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawnetwork/auth.dart';
import 'auth service test.mocks.dart';

@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authService = AuthService(firebaseAuth: mockFirebaseAuth);
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
  });

  group('AuthService Tests', () {
    test('signInWithEmailAndPassword returns a User on success', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('mock-uid');

      final user = await authService.signInWithEmailAndPassword('test@example.com', 'password123');
      expect(user, mockUser);
      expect(user?.uid, 'mock-uid');
    });

    test('signInWithEmailAndPassword returns null on failure', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final user = await authService.signInWithEmailAndPassword('wrong@example.com', 'wrongpassword');
      expect(user, null);
    });

    test('signUpWithEmailAndPassword returns a User on success', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('mock-uid');

      final user = await authService.signUpWithEmailAndPassword('test@example.com', 'password123');
      expect(user, mockUser);
      expect(user?.uid, 'mock-uid');
    });

    test('signOut calls FirebaseAuth.signOut', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('resetPassword calls FirebaseAuth.sendPasswordResetEmail', () async {
      when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email'))).thenAnswer((_) async {});

      await authService.resetPassword('test@example.com');
      verify(mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com')).called(1);
    });
  });
}
