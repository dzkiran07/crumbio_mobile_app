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

  Future<Either<Failure, bool>> logout();

  Future<Either<Failure, bool>> sendForgotPasswordOtp(String email);

  Future<Either<Failure, bool>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, bool>> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
