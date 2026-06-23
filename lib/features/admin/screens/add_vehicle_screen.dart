import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _seatsController = TextEditingController();
  final _fuelConsumptionController = TextEditingController();
  final _urlController = TextEditingController();

  String _category = 'standard';
  String _transmission = 'Manuelle';
  String _fuelType = 'Essence';
  bool _available = true;
  bool _isLoading = false;
  final List<String> _localImages = [];
  final List<String> _urlImages = [];

  final List<String> _categories = [
    'standard', 'SUV', 'électrique', 'utilitaire', 'berline'
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _seatsController.dispose();
    _fuelConsumptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _localImages.add(image.path));
    }
  }

  void _addUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _urlImages.add(url);
        _urlController.clear();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_localImages.isEmpty && _urlImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une image (URL ou galerie)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final vehicle = VehicleModel(
      id: '',
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text) ?? DateTime.now().year,
      pricePerDay: double.tryParse(_priceController.text) ?? 0,
      images: _urlImages,
      description: _descriptionController.text.trim(),
      category: _category,
      available: _available,
      transmission: _transmission,
      seats: int.tryParse(_seatsController.text),
      fuelConsumption: double.tryParse(_fuelConsumptionController.text),
      fuelType: _fuelType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref.read(adminProvider.notifier).addVehicle(vehicle, _localImages);
    if (!context.mounted) return;
    setState(() => _isLoading = false);
    context.pop(success);
  }

  void _removeUrl(int index) {
    setState(() => _urlImages.removeAt(index));
  }

  void _removeLocal(int index) {
    setState(() => _localImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un véhicule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._urlImages.asMap().entries.map((e) => _buildUrlTile(e.value, e.key)),
                    ..._localImages.asMap().entries.map((e) => _buildLocalTile(e.value, e.key)),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_photo_alternate, size: 32, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'Coller une URL d\'image',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _addUrl,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _brandController,
                      label: 'Marque',
                      hint: 'Ex: Toyota',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      label: 'Modèle',
                      hint: 'Ex: Corolla',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _yearController,
                      label: 'Année',
                      hint: '2024',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Prix par jour (FCFA)',
                      hint: '25000',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _seatsController,
                      label: 'Places',
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _fuelConsumptionController,
                      label: 'Consommation (L/100km)',
                      hint: '7.5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'standard'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _transmission,
                      decoration: const InputDecoration(labelText: 'Transmission'),
                      items: ['Manuelle', 'Automatique']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _transmission = v ?? 'Manuelle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: const InputDecoration(labelText: 'Carburant'),
                      items: ['Essence', 'Diesel', 'Électrique', 'Hybride']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _fuelType = v ?? 'Essence'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponible à la location'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Description du véhicule...',
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Ajouter le véhicule',
                      onPressed: _handleSubmit,
                      icon: Icons.add_circle,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlTile(String url, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 80, height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 80, height: 80, color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                width: 80, height: 80, color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: () => _removeUrl(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalTile(String path, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path), width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80, height: 80, color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: () => _removeLocal(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
