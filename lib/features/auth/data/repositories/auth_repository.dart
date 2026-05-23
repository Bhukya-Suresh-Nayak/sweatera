import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result wrapper for auth operations
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final User user;
  const AuthSuccess(this.user);
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

/// AuthRepository — single source of truth for all authentication operations.
/// Wraps Firebase Auth and Google Sign-In with clean error handling.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // ─── Email / Password ────────────────────────────────────────────────────────

  /// Sign in with email and password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return AuthFailure('An unexpected error occurred. Please try again.');
    }
  }

  /// Create a new account with email and password.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return AuthFailure('An unexpected error occurred. Please try again.');
    }
  }

  // ─── Google Sign-In ──────────────────────────────────────────────────────────

  /// Sign in with Google account.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthFailure('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return AuthSuccess(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return AuthFailure('Google sign-in failed. Please try again.');
    }
  }

  // ─── Phone / OTP ────────────────────────────────────────────────────────────

  /// Send OTP to a phone number.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) => onError(_mapFirebaseError(e)),
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify the OTP code entered by user.
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return AuthSuccess(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return AuthFailure('OTP verification failed. Please try again.');
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────────

  /// Sign out from all providers.
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Password Reset ──────────────────────────────────────────────────────────

  /// Send a password reset email.
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return AuthSuccess(_firebaseAuth.currentUser!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and retry.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
