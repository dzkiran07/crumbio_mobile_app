import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/app_usecase.dart';
import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecaseParams extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final String? bakeryName;

  const RegisterUsecaseParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.bakeryName,
  });

  @override
  List<Object?> get props => [fullName, email, phone, password, role, bakeryName];
}

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(authRepository: ref.read(authRepositoryProvider));
});

class RegisterUsecase implements UsecaseWithParams<AuthEntity, RegisterUsecaseParams> {
  final IAuthRepository _authRepository;

  RegisterUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterUsecaseParams params) {
    return _authRepository.register(
      fullName: params.fullName,
      email: params.email,
      phone: params.phone,
      password: params.password,
      role: params.role,
      bakeryName: params.bakeryName,
    );
  }
}
