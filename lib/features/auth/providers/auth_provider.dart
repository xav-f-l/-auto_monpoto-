import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isAdmin;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.isAdmin = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isAdmin,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isAdmin: isAdmin ?? this.isAdmin,
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
    await _loadUser(firebaseUser.uid);
  }

  Future<void> _loadUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isAdmin: user.isAdmin,
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
      final uid = credential.user!.uid;
      final now = DateTime.now();
      final user = UserModel(
        id: uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
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
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
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
