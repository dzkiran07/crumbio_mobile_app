import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/user_session_service.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_current_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_forgot_password_usecase.dart';
import '../../domain/usecases/send_forgot_password_otp_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../domain/usecases/verify_forgot_password_otp_usecase.dart';
import '../state/auth_state.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    loginUsecase: ref.read(loginUsecaseProvider),
    registerUsecase: ref.read(registerUsecaseProvider),
    logoutUsecase: ref.read(logoutUsecaseProvider),
    getCurrentUserUsecase: ref.read(getCurrentUserUsecaseProvider),
    updateProfileUsecase: ref.read(updateProfileUsecaseProvider),
    uploadProfileImageUsecase: ref.read(uploadProfileImageUsecaseProvider),
    changePasswordUsecase: ref.read(changePasswordUsecaseProvider),
    deleteAccountUsecase: ref.read(deleteAccountUsecaseProvider),
    sendForgotPasswordOtpUsecase: ref.read(sendForgotPasswordOtpUsecaseProvider),
    verifyForgotPasswordOtpUsecase: ref.read(verifyForgotPasswordOtpUsecaseProvider),
    resetForgotPasswordUsecase: ref.read(resetForgotPasswordUsecaseProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final UpdateProfileUsecase _updateProfileUsecase;
  final UploadProfileImageUsecase _uploadProfileImageUsecase;
  final ChangePasswordUsecase _changePasswordUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final SendForgotPasswordOtpUsecase _sendForgotPasswordOtpUsecase;
  final VerifyForgotPasswordOtpUsecase _verifyForgotPasswordOtpUsecase;
  final ResetForgotPasswordUsecase _resetForgotPasswordUsecase;
  final UserSessionService _userSessionService;

  AuthViewModel({
    required LoginUsecase loginUsecase,
    required RegisterUsecase registerUsecase,
    required LogoutUsecase logoutUsecase,
    required GetCurrentUserUsecase getCurrentUserUsecase,
    required UpdateProfileUsecase updateProfileUsecase,
    required UploadProfileImageUsecase uploadProfileImageUsecase,
    required ChangePasswordUsecase changePasswordUsecase,
    required DeleteAccountUsecase deleteAccountUsecase,
    required SendForgotPasswordOtpUsecase sendForgotPasswordOtpUsecase,
    required VerifyForgotPasswordOtpUsecase verifyForgotPasswordOtpUsecase,
    required ResetForgotPasswordUsecase resetForgotPasswordUsecase,
    required UserSessionService userSessionService,
  }) : _loginUsecase = loginUsecase,
       _registerUsecase = registerUsecase,
       _logoutUsecase = logoutUsecase,
       _getCurrentUserUsecase = getCurrentUserUsecase,
       _updateProfileUsecase = updateProfileUsecase,
       _uploadProfileImageUsecase = uploadProfileImageUsecase,
       _changePasswordUsecase = changePasswordUsecase,
       _deleteAccountUsecase = deleteAccountUsecase,
       _sendForgotPasswordOtpUsecase = sendForgotPasswordOtpUsecase,
       _verifyForgotPasswordOtpUsecase = verifyForgotPasswordOtpUsecase,
       _resetForgotPasswordUsecase = resetForgotPasswordUsecase,
       _userSessionService = userSessionService,
       super(const AuthState());

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _loginUsecase(LoginUsecaseParams(email: email, password: password));

    AuthEntity? loggedInUser;
    final success = result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) {
        loggedInUser = user;
        return true;
      },
    );
    if (!success || loggedInUser == null) return false;

    // Keep the fingerprint-login credential cache fresh on every successful
    // login, mirroring AgriBridge — enabling biometric login later (from the
    // Security screen) just flips a flag rather than needing a fresh
    // password entry at that point.
    try {
      await _userSessionService.syncBiometricStateAfterLogin(loggedInUserId: loggedInUser!.id);
      await _userSessionService.saveBiometricCredentials(email: email, password: password);
    } catch (_) {
      // Keep login successful even if secure storage write fails.
    }

    state = state.copyWith(status: AuthStatus.authenticated, authEntity: loggedInUser);
    return true;
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

  Future<bool> updateProfile({String? fullName, String? phone, String? address}) async {
    final result = await _updateProfileUsecase(
      fullName: fullName,
      phone: phone,
      address: address,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, authEntity: user);
        return true;
      },
    );
  }

  Future<bool> uploadProfileImage(String filePath) async {
    final result = await _uploadProfileImageUsecase(filePath);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, authEntity: user);
        return true;
      },
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _changePasswordUsecase(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> deleteAccount({required String currentPassword}) async {
    final result = await _deleteAccountUsecase(currentPassword: currentPassword);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return true;
      },
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
