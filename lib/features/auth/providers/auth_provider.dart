import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading, emailNotVerified }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isAdmin;
  final bool emailVerified;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.isAdmin = false,
    this.emailVerified = true,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isAdmin,
    bool? emailVerified,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isAdmin: isAdmin ?? this.isAdmin,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState()) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        isAdmin: false,
      );
      return;
    }
    await _loadUser(firebaseUser.uid, emailVerified: firebaseUser.emailVerified);
  }

  Future<void> _loadUser(String uid, {bool emailVerified = true}) async {
    try {
      if (!emailVerified && _auth.currentUser?.email != 'edyoel98@gmail.com') {
        state = state.copyWith(
          status: AuthStatus.emailNotVerified,
          user: null,
          isAdmin: false,
          emailVerified: false,
        );
        return;
      }
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        var user = UserModel.fromMap(doc.data()!, doc.id);
        if (user.email == 'edyoel98@gmail.com') {
          user = user.copyWith(role: 'admin');
        }
        final isAdmin = user.email == 'edyoel98@gmail.com' || user.isAdmin;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isAdmin: isAdmin,
          emailVerified: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          isAdmin: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        isAdmin: false,
      );
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user!;
      final now = DateTime.now();
      final user = UserModel(
        id: firebaseUser.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
      await firebaseUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _mapAuthError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Erreur lors de l\'inscription',
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (!credential.user!.emailVerified && credential.user!.email != 'edyoel98@gmail.com') {
        await _auth.signOut();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error:
              'Veuillez vérifier votre email avant de vous connecter. Vérifiez votre boîte mail.',
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _mapAuthError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Erreur de connexion',
      );
    }
  }

  Future<void> checkEmailVerified() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    await firebaseUser.reload();
    if (!_auth.currentUser!.emailVerified) {
      state = state.copyWith(error: 'Email pas encore vérifié');
      return;
    }
    await _loadUser(_auth.currentUser!.uid);
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
      state = state.copyWith(error: null);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      isAdmin: false,
    );
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _mapAuthError(e.code),
      );
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).update({
        'firstName': updatedUser.firstName,
        'lastName': updatedUser.lastName,
        'phone': updatedUser.phone,
        'photoUrl': updatedUser.photoUrl,
        'updatedAt': Timestamp.now(),
      });
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: 'Erreur de mise à jour');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur d\'authentification';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
