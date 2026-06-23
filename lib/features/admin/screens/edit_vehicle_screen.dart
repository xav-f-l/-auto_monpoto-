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

class EditVehicleScreen extends ConsumerStatefulWidget {
  final VehicleModel vehicle;
  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _yearController;
  late final TextEditingController _seatsController;
  late final TextEditingController _fuelConsumptionController;
  late final TextEditingController _locationController;
  final _urlController = TextEditingController();

  late String _category;
  late String _transmission;
  late String _fuelType;
  late bool _available;
  late List<String> _existingImages;
  final List<String> _newImages = [];
  bool _isSaving = false;

  final List<String> _categories = [
    'standard', 'SUV', 'électrique', 'utilitaire', 'berline'
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandController = TextEditingController(text: v.brand);
    _modelController = TextEditingController(text: v.model);
    _descriptionController = TextEditingController(text: v.description);
    _priceController = TextEditingController(text: v.pricePerDay.toStringAsFixed(0));
    _yearController = TextEditingController(text: v.year.toString());
    _seatsController = TextEditingController(text: v.seats?.toString() ?? '');
    _fuelConsumptionController = TextEditingController(text: v.fuelConsumption?.toString() ?? '');
    _locationController = TextEditingController(text: v.location ?? '');
    _category = v.category;
    _transmission = v.transmission ?? 'Manuelle';
    _fuelType = v.fuelType ?? 'Essence';
    _available = v.available;
    _existingImages = List.from(v.images);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _seatsController.dispose();
    _fuelConsumptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newImages.add(image.path));
    }
  }

  void _addUrlImage() {
    if (_urlController.text.trim().isNotEmpty) {
      setState(() {
        _existingImages.add(_urlController.text.trim());
        _urlController.clear();
      });
    }
  }

  void _removeImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingImages.removeAt(index);
      } else {
        _newImages.removeAt(index);
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = widget.vehicle.copyWith(
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text) ?? widget.vehicle.year,
      pricePerDay: double.tryParse(_priceController.text) ?? widget.vehicle.pricePerDay,
      images: _existingImages,
      description: _descriptionController.text.trim(),
      category: _category,
      available: _available,
      transmission: _transmission,
      seats: int.tryParse(_seatsController.text),
      fuelConsumption: double.tryParse(_fuelConsumptionController.text),
      fuelType: _fuelType,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );

    await ref.read(adminProvider.notifier).updateVehicle(updated, _newImages);
    if (!context.mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le véhicule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImages.asMap().entries.map((e) => _buildImageTile(e.value, e.key, true)),
                    ..._newImages.asMap().entries.map((e) => _buildLocalImageTile(e.value, e.key)),
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
                    child: CustomTextField(
                      controller: _urlController,
                      label: 'Ajouter par URL',
                      hint: "https://...",
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _addUrlImage,
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
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      label: 'Modèle',
                      hint: 'Ex: Corolla',
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
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
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
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
              CustomTextField(
                controller: _locationController,
                label: 'Localisation',
                hint: 'Douala - Bonanjo',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'standard'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _transmission,
                      decoration: const InputDecoration(labelText: 'Transmission'),
                      items: ['Manuelle', 'Automatique'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _transmission = v ?? 'Manuelle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: const InputDecoration(labelText: 'Carburant'),
                      items: ['Essence', 'Diesel', 'Électrique', 'Hybride'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Enregistrer les modifications',
                      onPressed: _handleSave,
                      icon: Icons.save,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(String url, int index, bool isExisting) {
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
              placeholder: (_, __) => Container(color: Colors.grey[200], width: 80, height: 80),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: () => _removeImage(index, isExisting),
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImageTile(String path, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 80, height: 80,
                child: const Icon(Icons.broken_image)),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: () => _removeImage(index, false),
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
