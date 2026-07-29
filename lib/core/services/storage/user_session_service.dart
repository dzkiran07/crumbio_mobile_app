import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService();
});

class BiometricCredentials {
  final String email;
  final String password;

  const BiometricCredentials({required this.email, required this.password});
}

class UserSessionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricEnabledUserId = 'biometric_enabled_user_id';
  static const String _keyBiometricCredentialsPrefix = 'biometric_credentials_';

  // Save token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> saveCurrentUserId(String userId) async {
    await _secureStorage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getCurrentUserId() async {
    return await _secureStorage.read(key: _keyUserId);
  }

  
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyToken);
    await _secureStorage.delete(key: _keyUserId);
  }

  Future<bool> isBiometricLoginEnabled() async {
    return await _secureStorage.read(key: _keyBiometricEnabled) == 'true';
  }

  Future<bool> isBiometricLoginEnabledForCurrentUser() async {
    if (!await isBiometricLoginEnabled()) return false;

    final currentUserId = (await getCurrentUserId())?.trim();
    final ownerUserId = (await getBiometricEnabledUserId())?.trim();
    if (currentUserId == null || currentUserId.isEmpty) return false;
    if (ownerUserId == null || ownerUserId.isEmpty) return false;
    return currentUserId == ownerUserId;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: enabled.toString());
    if (enabled) {
      final currentUserId = await getCurrentUserId();
      if (currentUserId != null && currentUserId.trim().isNotEmpty) {
        await _secureStorage.write(key: _keyBiometricEnabledUserId, value: currentUserId);
      }
      return;
    }

    final ownerUserId = await getBiometricEnabledUserId();
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      await clearBiometricCredentialsForUser(ownerUserId);
    }
    await _secureStorage.delete(key: _keyBiometricEnabledUserId);
  }

  Future<String?> getBiometricEnabledUserId() async {
    return await _secureStorage.read(key: _keyBiometricEnabledUserId);
  }

  Future<void> syncBiometricStateAfterLogin({required String loggedInUserId}) async {
    final enabled = await isBiometricLoginEnabled();
    if (!enabled) return;

    final ownerUserId = await getBiometricEnabledUserId();
    final normalizedLoggedInUserId = loggedInUserId.trim();
    final normalizedOwnerUserId = ownerUserId?.trim() ?? '';

    if (normalizedOwnerUserId.isEmpty) {
      await _secureStorage.write(
        key: _keyBiometricEnabledUserId,
        value: normalizedLoggedInUserId,
      );
    }
  }

  String _biometricCredentialsKey(String userId) {
    return '$_keyBiometricCredentialsPrefix${userId.trim()}';
  }

  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null || currentUserId.trim().isEmpty) return;

    await saveBiometricCredentialsForUser(
      userId: currentUserId,
      email: email,
      password: password,
    );
  }

  Future<void> saveBiometricCredentialsForUser({
    required String userId,
    required String email,
    required String password,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedEmail = email.trim();
    if (trimmedUserId.isEmpty || trimmedEmail.isEmpty || password.isEmpty) return;

    final payload = jsonEncode({'email': trimmedEmail, 'password': password});
    await _secureStorage.write(key: _biometricCredentialsKey(trimmedUserId), value: payload);
  }

  Future<BiometricCredentials?> getBiometricCredentials() async {
    if (!await isBiometricLoginEnabled()) return null;

    final ownerUserId = await getBiometricEnabledUserId();
    if (ownerUserId == null || ownerUserId.trim().isEmpty) return null;

    return getBiometricCredentialsForUser(ownerUserId);
  }

  Future<BiometricCredentials?> getBiometricCredentialsForUser(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) return null;

    final raw = await _secureStorage.read(key: _biometricCredentialsKey(trimmedUserId));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final email = (decoded['email'] as String?)?.trim() ?? '';
      final password = decoded['password'] as String?;
      if (email.isEmpty || password == null || password.isEmpty) return null;
      return BiometricCredentials(email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasBiometricCredentials() async {
    return await getBiometricCredentials() != null;
  }

  Future<bool> hasBiometricCredentialsForCurrentUser() async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null || currentUserId.trim().isEmpty) return false;

    final credentials = await getBiometricCredentialsForUser(currentUserId);
    return credentials != null;
  }

  Future<void> clearBiometricCredentialsForUser(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) return;
    await _secureStorage.delete(key: _biometricCredentialsKey(trimmedUserId));
  }

  Future<void> clearBiometricLoginSetup() async {
    final ownerUserId = await getBiometricEnabledUserId();
    if (ownerUserId != null && ownerUserId.trim().isNotEmpty) {
      await clearBiometricCredentialsForUser(ownerUserId);
    }
    await _secureStorage.delete(key: _keyBiometricEnabled);
    await _secureStorage.delete(key: _keyBiometricEnabledUserId);
  }

  Future<void> clearBiometricDataForCurrentUser() async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null || currentUserId.trim().isEmpty) return;

    await clearBiometricCredentialsForUser(currentUserId);
    final ownerUserId = (await getBiometricEnabledUserId())?.trim();
    if (ownerUserId == currentUserId.trim()) {
      await _secureStorage.delete(key: _keyBiometricEnabled);
      await _secureStorage.delete(key: _keyBiometricEnabledUserId);
    }
  }
}
