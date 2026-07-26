class OrderItemEntity {
  final String productId;
  final String productName;
  final String size;
  final String? flavor;
  final double unitPrice;
  final int quantity;

  OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.size,
    this.flavor,
    required this.unitPrice,
    required this.quantity,
  });
}

class OrderEntity {
  final String id;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final String status;
  final String fulfillmentType;
  final String? deliveryAddress;
  final String? pickupNote;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  OrderEntity({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.fulfillmentType,
    this.deliveryAddress,
    this.pickupNote,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });
}
