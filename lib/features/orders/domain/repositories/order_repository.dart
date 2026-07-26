import '../entities/order_entity.dart';

class CreateOrderItemParams {
  final String productId;
  final String size;
  final String? flavor;
  final int quantity;

  CreateOrderItemParams({
    required this.productId,
    required this.size,
    this.flavor,
    required this.quantity,
  });
}

class CreateOrderParams {
  final List<CreateOrderItemParams> items;
  final String fulfillmentType;
  final String? deliveryAddress;
  final String? pickupNote;
  final String paymentMethod;

  CreateOrderParams({
    required this.items,
    required this.fulfillmentType,
    this.deliveryAddress,
    this.pickupNote,
    required this.paymentMethod,
  });
}

abstract class OrderRepository {
  Future<OrderEntity> createOrder(CreateOrderParams params);
  Future<List<OrderEntity>> getMyOrders();
}
