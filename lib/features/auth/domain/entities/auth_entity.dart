import 'package:equatable/equatable.dart';

enum UserRole { buyer, baker, admin }

UserRole userRoleFromWire(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.buyer,
  );
}

class AuthEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? bakeryName;
  final String? address;
  final String? profileImage;
  final bool isActive;

  const AuthEntity({
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

  bool get isBaker => role == UserRole.baker;
  bool get isBuyer => role == UserRole.buyer;

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    bakeryName,
    address,
    profileImage,
    isActive,
  ];
}
