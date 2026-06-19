import 'package:equatable/equatable.dart';

class UserDocument extends Equatable {
  final String id;
  final String type;
  final String url;
  final String fileName;
  final bool verified;
  final DateTime uploadedAt;

  const UserDocument({
    required this.id,
    required this.type,
    required this.url,
    required this.fileName,
    this.verified = false,
    required this.uploadedAt,
  });

  String get typeLabel {
    switch (type) {
      case 'license':
        return 'Permis de conduire';
      case 'id_card':
        return 'Pièce d\'identité';
      case 'passport':
        return 'Passeport';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'url': url,
        'fileName': fileName,
        'verified': verified,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory UserDocument.fromMap(Map<String, dynamic> map, String id) {
    return UserDocument(
      id: id,
      type: map['type'] ?? '',
      url: map['url'] ?? '',
      fileName: map['fileName'] ?? '',
      verified: map['verified'] ?? false,
      uploadedAt: DateTime.parse(map['uploadedAt']),
    );
  }

  UserDocument copyWith({bool? verified}) {
    return UserDocument(
      id: id,
      type: type,
      url: url,
      fileName: fileName,
      verified: verified ?? this.verified,
      uploadedAt: uploadedAt,
    );
  }

  @override
  List<Object?> get props => [id, type, url, fileName, verified, uploadedAt];
}
