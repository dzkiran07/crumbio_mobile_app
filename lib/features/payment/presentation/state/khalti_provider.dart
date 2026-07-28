import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../../data/datasources/khalti_remote_datasource.dart';

final khaltiRemoteDatasourceProvider = Provider<KhaltiRemoteDatasource>((ref) {
  final apiClient = ApiClient(userSessionService: UserSessionService());
  return KhaltiRemoteDatasource(apiClient: apiClient);
});
