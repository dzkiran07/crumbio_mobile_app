import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoint.dart';
import '../../models/auth_api_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class AuthResponseModel {
  final AuthApiModel user;
  final String token;

  AuthResponseModel({required this.user, required this.token});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: AuthApiModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? bakeryName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          if (bakeryName != null) 'bakeryName': bakeryName,
        },
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Registration failed'));
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Login failed'));
    }
  }

  Future<AuthApiModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      return AuthApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not load profile'));
    }
  }

  Future<AuthApiModel> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.me,
        data: {
          if (fullName != null) 'fullName': fullName,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        },
      );
      return AuthApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not update profile'));
    }
  }

  Future<AuthApiModel> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.uploadFile(
        ApiEndpoints.uploadProfileImage,
        formData: formData,
      );
      return AuthApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not upload profile picture'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not change password'));
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.me,
        data: {'currentPassword': currentPassword},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not delete account'));
    }
  }

  Future<String> sendForgotPasswordOtp(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPasswordSendOtp,
        data: {'email': email},
      );
      return (response.data as Map<String, dynamic>)['message'] as String;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not send OTP'));
    }
  }

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPasswordVerifyOtp,
        data: {'email': email, 'otp': otp},
      );
      return (response.data as Map<String, dynamic>)['message'] as String;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Invalid OTP'));
    }
  }

  Future<String> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPasswordReset,
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
      return (response.data as Map<String, dynamic>)['message'] as String;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Could not reset password'));
    }
  }
}
