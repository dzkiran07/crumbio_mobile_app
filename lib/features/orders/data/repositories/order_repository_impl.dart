import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDatasource remoteDatasource;

  OrderRepositoryImpl({required this.remoteDatasource});

  @override
  Future<OrderEntity> createOrder(CreateOrderParams params) async {
    final order = await remoteDatasource.createOrder(params);
    return order.toEntity();
  }

  @override
  Future<List<OrderEntity>> getMyOrders() async {
    final orders = await remoteDatasource.fetchMyOrders();
    return orders.map((order) => order.toEntity()).toList();
  }
}
