import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  return UpdateProfileUsecase(authRepository: ref.read(authRepositoryProvider));
});

class UpdateProfileUsecase {
  final IAuthRepository _authRepository;

  UpdateProfileUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<Failure, AuthEntity>> call({
    String? fullName,
    String? phone,
    String? address,
  }) {
    return _authRepository.updateProfile(fullName: fullName, phone: phone, address: address);
  }
}
