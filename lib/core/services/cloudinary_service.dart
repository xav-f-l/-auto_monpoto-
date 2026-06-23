import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String _cloudName = 'dmx5im82g';
  static const String _uploadPreset = 'auto_monpoto';

  static final CloudinaryService _instance = CloudinaryService._();
  static CloudinaryService get instance => _instance;

  late final CloudinaryPublic _cloudinary;

  CloudinaryService._() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  Future<String> uploadFile(File file) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
    );
    return response.secureUrl;
  }
}
