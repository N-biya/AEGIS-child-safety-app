import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:aegis/services/auth_service.dart';

void main() {
  // ── TC-APP-001: Parent Account Registration ──────────────────────────────
  group('TC-APP-001 Parent Account Registration', () {
    test('valid sign-up creates an account and signs the parent in', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final auth = AuthService(auth: mockAuth);

      final error = await auth.signUp(
        'newparent@example.com',
        'strongPass123',
        'Jane Parent',
      );

      // Null return == success (the screen uses this to navigate to onboarding).
      expect(error, isNull);
      // Account now exists in (mock) Firebase Auth and a session is active.
      expect(mockAuth.currentUser, isNotNull);
      expect(auth.isLoggedIn, isTrue);
      expect(mockAuth.currentUser!.email, 'newparent@example.com');
    });

    test('duplicate email is reported with a clear message', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      final auth = AuthService(auth: mockAuth);

      final error =
          await auth.signUp('taken@example.com', 'strongPass123', 'Jane');

      expect(error, 'An account already exists with this email.');
    });
  });

  // ── TC-APP-003: Invalid Login Rejection ──────────────────────────────────
  group('TC-APP-003 Invalid Login Rejection', () {
    test('wrong credentials are rejected with no session issued', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final auth = AuthService(auth: mockAuth);

      final error = await auth.signIn('parent@example.com', 'wrongPassword');

      // A user-facing error is shown...
      expect(error, 'No account found with this email or password.');
      // ...and no token/session is issued — the user stays on the login screen.
      expect(mockAuth.currentUser, isNull);
      expect(auth.isLoggedIn, isFalse);
    });

    test('valid credentials succeed and open a session', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final auth = AuthService(auth: mockAuth);

      final error = await auth.signIn('parent@example.com', 'correctPassword');

      expect(error, isNull);
      expect(auth.isLoggedIn, isTrue);
    });
  });
}
