import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/providers/notification_prefs_section.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadUserData);
  }

  void _loadUserData() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {}
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final updated = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    ref.read(authProvider.notifier).updateProfile(updated);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil mis à jour')),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Utilisateur non connecté')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.role == 'admin' ? 'Administrateur' : 'Client',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      label: 'Nom',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      label: 'Prénom',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Téléphone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Enregistrer',
                onPressed: _saveProfile,
                icon: Icons.save,
              ),
            ] else ...[
              _buildInfoTile(Icons.person, 'Nom', user.fullName),
              _buildInfoTile(Icons.phone, 'Téléphone', user.phone),
              _buildInfoTile(Icons.email, 'Email', user.email),
              _buildInfoTile(
                Icons.calendar_today,
                'Membre depuis',
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.book_online, color: AppColors.primary),
              title: const Text('Mes réservations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my-bookings'),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: AppColors.warning),
              title: const Text('Mes documents'),
              subtitle: const Text('Permis, pièce d\'identité'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/documents'),
            ),
            SwitchListTile(
              secondary: Icon(
                ref.watch(themeProvider) == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: AppColors.textSecondary,
              ),
              title: const Text('Mode sombre'),
              value: ref.watch(themeProvider) == ThemeMode.dark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
            const Divider(),
            const NotificationPrefsSection(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: const Text('À propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Se déconnecter',
              onPressed: _confirmLogout,
              backgroundColor: AppColors.error,
              icon: Icons.logout,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
