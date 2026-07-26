import '../../domain/entities/auth_entity.dart';

class AuthApiModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? bakeryName;
  final String? address;
  final String? profileImage;
  final bool isActive;

  AuthApiModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.bakeryName,
    this.address,
    this.profileImage,
    this.isActive = true,
  });

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      bakeryName: json['bakeryName'] as String?,
      address: json['address'] as String?,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'bakeryName': bakeryName,
      'address': address,
      'profileImage': profileImage,
      'isActive': isActive,
    };
  }

  AuthEntity toEntity() {
    return AuthEntity(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: userRoleFromWire(role),
      bakeryName: bakeryName,
      address: address,
      profileImage: profileImage,
      isActive: isActive,
    );
  }
}
