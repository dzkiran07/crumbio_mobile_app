import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/app_usecase.dart';
import '../../data/repositories/auth_repository.dart';
import '../repositories/auth_repository.dart';

class VerifyForgotPasswordOtpUsecaseParams extends Equatable {
  final String email;
  final String otp;

  const VerifyForgotPasswordOtpUsecaseParams({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

final verifyForgotPasswordOtpUsecaseProvider = Provider<VerifyForgotPasswordOtpUsecase>((ref) {
  return VerifyForgotPasswordOtpUsecase(authRepository: ref.read(authRepositoryProvider));
});

class VerifyForgotPasswordOtpUsecase
    implements UsecaseWithParams<bool, VerifyForgotPasswordOtpUsecaseParams> {
  final IAuthRepository _authRepository;

  VerifyForgotPasswordOtpUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(VerifyForgotPasswordOtpUsecaseParams params) {
    return _authRepository.verifyForgotPasswordOtp(email: params.email, otp: params.otp);
  }
}
