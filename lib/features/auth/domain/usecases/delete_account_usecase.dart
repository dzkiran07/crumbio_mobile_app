import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/auth_repository.dart';
import '../repositories/auth_repository.dart';

final deleteAccountUsecaseProvider = Provider<DeleteAccountUsecase>((ref) {
  return DeleteAccountUsecase(authRepository: ref.read(authRepositoryProvider));
});

class DeleteAccountUsecase {
  final IAuthRepository _authRepository;

  DeleteAccountUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<Failure, bool>> call({required String currentPassword}) {
    return _authRepository.deleteAccount(currentPassword: currentPassword);
  }
}
