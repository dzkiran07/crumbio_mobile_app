import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/app_usecase.dart';
import '../../data/repositories/auth_repository.dart';
import '../repositories/auth_repository.dart';

class ResetForgotPasswordUsecaseParams extends Equatable {
  final String email;
  final String otp;
  final String newPassword;

  const ResetForgotPasswordUsecaseParams({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

final resetForgotPasswordUsecaseProvider = Provider<ResetForgotPasswordUsecase>((ref) {
  return ResetForgotPasswordUsecase(authRepository: ref.read(authRepositoryProvider));
});

class ResetForgotPasswordUsecase
    implements UsecaseWithParams<bool, ResetForgotPasswordUsecaseParams> {
  final IAuthRepository _authRepository;

  ResetForgotPasswordUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(ResetForgotPasswordUsecaseParams params) {
    return _authRepository.resetForgotPassword(
      email: params.email,
      otp: params.otp,
      newPassword: params.newPassword,
    );
  }
}
