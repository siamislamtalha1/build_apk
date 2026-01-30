import 'package:flutter_test/flutter_test.dart';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Fake User
class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_uid';
  @override
  String get email => 'test@example.com';
}

// Fake AuthService
class FakeAuthService implements AuthService {
  final _userController = StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _userController.stream;

  @override
  User? get currentUser => null;

  @override
  bool get isGuest => false;

  @override
  Future<UserCredential?> signInAsGuest() async {
    _userController.add(FakeUser());
    return null; // Credential doesn't matter for this test
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    _userController.add(FakeUser());
    return null;
  }

  // Implement other required members as no-ops or throws if not used
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Auth Flow "Magic" Tests', () {
    late AuthCubit authCubit;
    late FakeAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeAuthService();
      authCubit = AuthCubit(authService: fakeAuthService);
    });

    tearDown(() {
      authCubit.close();
    });

    test('signInWithGoogle emits Authenticated state on success', () async {
      // Act
      final future = authCubit.signInWithGoogle();

      // Assert
      await expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ]),
      );
      await future;
    });

    test('signInAsGuest emits Authenticated state on success', () async {
      // Act
      final future = authCubit.signInAsGuest();

      // Assert
      await expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ]),
      );
      await future;
    });
  });
}
