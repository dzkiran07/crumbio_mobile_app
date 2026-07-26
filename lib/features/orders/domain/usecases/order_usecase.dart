import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrderUseCase {
  final OrderRepository repository;

  CreateOrderUseCase(this.repository);

  Future<OrderEntity> call(CreateOrderParams params) async {
    return await repository.createOrder(params);
  }
}

class GetMyOrdersUseCase {
  final OrderRepository repository;

  GetMyOrdersUseCase(this.repository);

  Future<List<OrderEntity>> call() async {
    return await repository.getMyOrders();
  }
}
