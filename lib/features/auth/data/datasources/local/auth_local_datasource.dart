import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/hive/hive_service.dart';
import '../../../../../core/services/storage/user_session_service.dart';
import '../../models/auth_api_model.dart';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasource(
    hiveService: ref.read(hiveServiceProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthLocalDatasource {
  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  AuthLocalDatasource({
    required HiveService hiveService,
    required UserSessionService userSessionService,
  }) : _hiveService = hiveService,
       _userSessionService = userSessionService;

  Future<void> cacheSession({required AuthApiModel user, required String token}) async {
    await _userSessionService.saveToken(token);
    await _hiveService.saveCurrentUser(user.toJson());
  }

  AuthApiModel? getCachedUser() {
    final json = _hiveService.getCurrentUser();
    if (json == null) return null;
    return AuthApiModel.fromJson(json);
  }

  Future<void> clearSession() async {
    await _userSessionService.clearSession();
    await _hiveService.clearCurrentUser();
  }
}
