import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/user_document.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/cloudinary_service.dart';

class DocumentState {
  final List<UserDocument> documents;
  final bool isLoading;
  final String? error;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });

  DocumentState copyWith({
    List<UserDocument>? documents,
    bool? isLoading,
    String? error,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService.instance;
  String? _userId;

  DocumentNotifier() : super(const DocumentState());

  void setUserId(String userId) {
    _userId = userId;
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('documents')
          .orderBy('uploadedAt', descending: true)
          .get();
      final docs = snapshot.docs
          .map((doc) => UserDocument.fromMap(doc.data(), doc.id))
          .toList();
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> uploadDocument({
    required File file,
    required String type,
  }) async {
    if (_userId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url = await _cloudinary.uploadFile(file);

      final doc = {
        'type': type,
        'url': url,
        'fileName': file.path.split('/').last,
        'verified': false,
        'uploadedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('documents')
          .add(doc);

      await loadDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur d\'upload');
      return false;
    }
  }

  Future<void> deleteDocument(String docId) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('documents')
          .doc(docId)
          .delete();
      await loadDocuments();
    } catch (_) {}
  }
}

final documentProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  final notifier = DocumentNotifier();
  final authState = ref.watch(authProvider);
  if (authState.user != null) {
    notifier.setUserId(authState.user!.id);
  }
  return notifier;
});
