import '../../domain/entities/order_entity.dart';

class OrderItemApiModel {
  final String productId;
  final String productName;
  final String size;
  final String? flavor;
  final double unitPrice;
  final int quantity;

  OrderItemApiModel({
    required this.productId,
    required this.productName,
    required this.size,
    this.flavor,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItemApiModel.fromJson(Map<String, dynamic> json) {
    return OrderItemApiModel(
      productId: json['product'] as String,
      productName: json['productName'] as String,
      size: json['size'] as String,
      flavor: json['flavor'] as String?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      productId: productId,
      productName: productName,
      size: size,
      flavor: flavor,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}

class OrderApiModel {
  final String id;
  final List<OrderItemApiModel> items;
  final double totalAmount;
  final String status;
  final String fulfillmentType;
  final String? deliveryAddress;
  final String? pickupNote;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  OrderApiModel({
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

  factory OrderApiModel.fromJson(Map<String, dynamic> json) {
    return OrderApiModel(
      id: json['_id'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItemApiModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      fulfillmentType: json['fulfillmentType'] as String,
      deliveryAddress: json['deliveryAddress'] as String?,
      pickupNote: json['pickupNote'] as String?,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      items: items.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      status: status,
      fulfillmentType: fulfillmentType,
      deliveryAddress: deliveryAddress,
      pickupNote: pickupNote,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
    );
  }
}
