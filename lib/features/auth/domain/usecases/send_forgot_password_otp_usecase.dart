import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/app_usecase.dart';
import '../../data/repositories/auth_repository.dart';
import '../repositories/auth_repository.dart';

class SendForgotPasswordOtpUsecaseParams extends Equatable {
  final String email;

  const SendForgotPasswordOtpUsecaseParams({required this.email});

  @override
  List<Object?> get props => [email];
}

final sendForgotPasswordOtpUsecaseProvider = Provider<SendForgotPasswordOtpUsecase>((ref) {
  return SendForgotPasswordOtpUsecase(authRepository: ref.read(authRepositoryProvider));
});

class SendForgotPasswordOtpUsecase
    implements UsecaseWithParams<bool, SendForgotPasswordOtpUsecaseParams> {
  final IAuthRepository _authRepository;

  SendForgotPasswordOtpUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(SendForgotPasswordOtpUsecaseParams params) {
    return _authRepository.sendForgotPasswordOtp(params.email);
  }
}
