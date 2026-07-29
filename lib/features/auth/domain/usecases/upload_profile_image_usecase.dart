import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

final uploadProfileImageUsecaseProvider = Provider<UploadProfileImageUsecase>((ref) {
  return UploadProfileImageUsecase(authRepository: ref.read(authRepositoryProvider));
});

class UploadProfileImageUsecase {
  final IAuthRepository _authRepository;

  UploadProfileImageUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<Failure, AuthEntity>> call(String filePath) {
    return _authRepository.uploadProfileImage(filePath);
  }
}
