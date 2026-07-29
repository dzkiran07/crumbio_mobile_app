import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? bakeryName,
  });

  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthEntity>> getCurrentUser();

  Future<Either<Failure, AuthEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  });

  Future<Either<Failure, AuthEntity>> uploadProfileImage(String filePath);

  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, bool>> deleteAccount({required String currentPassword});

  Future<Either<Failure, bool>> logout();
}
