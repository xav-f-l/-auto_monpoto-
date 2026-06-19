import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  String _category = 'standard';
  String _transmission = 'Manuelle';
  String _fuelType = 'Essence';
  bool _available = true;
  final List<String> _selectedImages = [];

  final List<String> _categories = [
    'standard',
    'SUV',
    'électrique',
    'utilitaire',
    'berline'
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImages.add(image.path));
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = VehicleModel(
      id: '',
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text) ?? DateTime.now().year,
      pricePerDay: double.tryParse(_priceController.text) ?? 0,
      images: _selectedImages,
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

    ref.read(adminProvider.notifier).addVehicle(vehicle, _selectedImages);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Véhicule ajouté avec succès')),
    );
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
              const Text('Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ..._selectedImages.map((path) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      )),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate,
                          size: 32, color: AppColors.textSecondary),
                    ),
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
                      decoration:
                          const InputDecoration(labelText: 'Transmission'),
                      items: ['Manuelle', 'Automatique']
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _transmission = v ?? 'Manuelle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration:
                          const InputDecoration(labelText: 'Carburant'),
                      items: ['Essence', 'Diesel', 'Électrique', 'Hybride']
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _fuelType = v ?? 'Essence'),
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
              CustomButton(
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
}
