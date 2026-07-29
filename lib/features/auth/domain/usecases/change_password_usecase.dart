import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/auth_repository.dart';
import '../repositories/auth_repository.dart';

final changePasswordUsecaseProvider = Provider<ChangePasswordUsecase>((ref) {
  return ChangePasswordUsecase(authRepository: ref.read(authRepositoryProvider));
});

class ChangePasswordUsecase {
  final IAuthRepository _authRepository;

  ChangePasswordUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<Failure, bool>> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
