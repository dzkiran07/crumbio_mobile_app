import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/get_current_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_forgot_password_usecase.dart';
import '../../domain/usecases/send_forgot_password_otp_usecase.dart';
import '../../domain/usecases/verify_forgot_password_otp_usecase.dart';
import '../state/auth_state.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    loginUsecase: ref.read(loginUsecaseProvider),
    registerUsecase: ref.read(registerUsecaseProvider),
    logoutUsecase: ref.read(logoutUsecaseProvider),
    getCurrentUserUsecase: ref.read(getCurrentUserUsecaseProvider),
    sendForgotPasswordOtpUsecase: ref.read(sendForgotPasswordOtpUsecaseProvider),
    verifyForgotPasswordOtpUsecase: ref.read(verifyForgotPasswordOtpUsecaseProvider),
    resetForgotPasswordUsecase: ref.read(resetForgotPasswordUsecaseProvider),
  );
});

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final SendForgotPasswordOtpUsecase _sendForgotPasswordOtpUsecase;
  final VerifyForgotPasswordOtpUsecase _verifyForgotPasswordOtpUsecase;
  final ResetForgotPasswordUsecase _resetForgotPasswordUsecase;

  AuthViewModel({
    required LoginUsecase loginUsecase,
    required RegisterUsecase registerUsecase,
    required LogoutUsecase logoutUsecase,
    required GetCurrentUserUsecase getCurrentUserUsecase,
    required SendForgotPasswordOtpUsecase sendForgotPasswordOtpUsecase,
    required VerifyForgotPasswordOtpUsecase verifyForgotPasswordOtpUsecase,
    required ResetForgotPasswordUsecase resetForgotPasswordUsecase,
  }) : _loginUsecase = loginUsecase,
       _registerUsecase = registerUsecase,
       _logoutUsecase = logoutUsecase,
       _getCurrentUserUsecase = getCurrentUserUsecase,
       _sendForgotPasswordOtpUsecase = sendForgotPasswordOtpUsecase,
       _verifyForgotPasswordOtpUsecase = verifyForgotPasswordOtpUsecase,
       _resetForgotPasswordUsecase = resetForgotPasswordUsecase,
       super(const AuthState());

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _loginUsecase(LoginUsecaseParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, authEntity: user);
        return true;
      },
    );
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? bakeryName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _registerUsecase(
      RegisterUsecaseParams(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
        bakeryName: bakeryName,
      ),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, authEntity: user);
        return true;
      },
    );
  }

  Future<void> loadCurrentUser() async {
    final result = await _getCurrentUserUsecase();
    result.fold(
      (failure) => state = state.copyWith(status: AuthStatus.unauthenticated),
      (user) => state = state.copyWith(status: AuthStatus.authenticated, authEntity: user),
    );
  }

  Future<void> logout() async {
    await _logoutUsecase();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> sendForgotPasswordOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _sendForgotPasswordOtpUsecase(
      SendForgotPasswordOtpUsecaseParams(email: email),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial, infoMessage: 'OTP sent to your email.');
        return true;
      },
    );
  }

  Future<bool> verifyForgotPasswordOtp({required String email, required String otp}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _verifyForgotPasswordOtpUsecase(
      VerifyForgotPasswordOtpUsecaseParams(email: email, otp: otp),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial);
        return true;
      },
    );
  }

  Future<bool> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _resetForgotPasswordUsecase(
      ResetForgotPasswordUsecaseParams(email: email, otp: otp, newPassword: newPassword),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial);
        return true;
      },
    );
  }
}
