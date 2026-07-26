import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoint.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_api_model.dart';

class OrderRemoteDatasource {
  final ApiClient apiClient;

  OrderRemoteDatasource({required this.apiClient});

  Future<OrderApiModel> createOrder(CreateOrderParams params) async {
    final response = await apiClient.post(
      ApiEndpoints.orders,
      data: {
        'items': params.items
            .map((item) => {
                  'product': item.productId,
                  'size': item.size,
                  if (item.flavor != null) 'flavor': item.flavor,
                  'quantity': item.quantity,
                })
            .toList(),
        'fulfillmentType': params.fulfillmentType,
        if (params.deliveryAddress != null) 'deliveryAddress': params.deliveryAddress,
        if (params.pickupNote != null) 'pickupNote': params.pickupNote,
        'paymentMethod': params.paymentMethod,
      },
    );
    return OrderApiModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrderApiModel>> fetchMyOrders() async {
    final response = await apiClient.get(ApiEndpoints.myOrders);
    final data = response.data;
    if (data is List) {
      return data.map((item) => OrderApiModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Invalid response format for orders');
  }
}
