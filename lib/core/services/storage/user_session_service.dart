import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// NOTE: only the token slice of AgriBridge's UserSessionService is adapted
// here — the cart caching and biometric login logic belong to features we
// haven't built (or don't need) and are left out.
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService();
});

class UserSessionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';

  // Save token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyToken);
  }
}
