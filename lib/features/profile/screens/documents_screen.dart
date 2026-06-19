import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/document_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes documents'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                const Text(
                  'Documents requis pour la location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Téléchargez votre permis de conduire et votre pièce d\'identité pour faciliter vos réservations.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                _buildDocCard(
                  context,
                  ref,
                  icon: Icons.drive_eta,
                  label: 'Permis de conduire',
                  type: 'license',
                  state: state,
                ),
                const SizedBox(height: 12),
                _buildDocCard(
                  context,
                  ref,
                  icon: Icons.badge,
                  label: "Pièce d'identité",
                  type: 'id_card',
                  state: state,
                ),
                const SizedBox(height: 12),
                _buildDocCard(
                  context,
                  ref,
                  icon: Icons.book,
                  label: 'Passeport',
                  type: 'passport',
                  state: state,
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDocCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String type,
    required DocumentState state,
  }) {
    final existing =
        state.documents.where((d) => d.type == type).toList();
    final hasDoc = existing.isNotEmpty;
    final verified = existing.any((d) => d.verified);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              hasDoc ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            hasDoc ? Icons.check_circle : icon,
            color: hasDoc ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          hasDoc
              ? verified
                  ? 'Vérifié ✓'
                  : 'En attente de vérification'
              : 'Non téléchargé',
          style: TextStyle(
            color: verified
                ? AppColors.success
                : hasDoc
                    ? AppColors.warning
                    : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: hasDoc
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => ref
                    .read(documentProvider.notifier)
                    .deleteDocument(existing.first.id),
              )
            : IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.primary),
                onPressed: () => _pickAndUpload(ref, type),
              ),
      ),
    );
  }

  Future<void> _pickAndUpload(WidgetRef ref, String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ref
          .read(documentProvider.notifier)
          .uploadDocument(file: File(image.path), type: type);
    }
  }
}
