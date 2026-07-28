import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoint.dart';

class KhaltiInitiateResult {
  final String pidx;
  final String paymentUrl;

  KhaltiInitiateResult({required this.pidx, required this.paymentUrl});

  factory KhaltiInitiateResult.fromJson(Map<String, dynamic> json) {
    return KhaltiInitiateResult(
      pidx: json['pidx'] as String,
      paymentUrl: json['payment_url'] as String,
    );
  }
}

class KhaltiVerifyResult {
  final String orderId;
  final String paymentStatus;

  KhaltiVerifyResult({required this.orderId, required this.paymentStatus});

  factory KhaltiVerifyResult.fromJson(Map<String, dynamic> json) {
    return KhaltiVerifyResult(
      orderId: json['order'] as String,
      paymentStatus: json['paymentStatus'] as String,
    );
  }

  bool get isPaid => paymentStatus == 'paid';
}

class KhaltiRemoteDatasource {
  final ApiClient apiClient;

  KhaltiRemoteDatasource({required this.apiClient});

  Future<KhaltiInitiateResult> initiate({
    required String orderId,
    required String returnUrl,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.khaltiInitiate,
      data: {'orderId': orderId, 'returnUrl': returnUrl},
    );
    return KhaltiInitiateResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<KhaltiVerifyResult> verify(String pidx) async {
    final response = await apiClient.post(
      ApiEndpoints.khaltiVerify,
      data: {'pidx': pidx},
    );
    return KhaltiVerifyResult.fromJson(response.data as Map<String, dynamic>);
  }
}
