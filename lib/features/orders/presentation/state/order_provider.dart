import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecase.dart';

final _orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final apiClient = ApiClient(userSessionService: UserSessionService());
  final remote = OrderRemoteDatasource(apiClient: apiClient);
  return OrderRepositoryImpl(remoteDatasource: remote);
});

final myOrdersProvider =
    StateNotifierProvider<MyOrdersNotifier, AsyncValue<List<OrderEntity>>>((ref) {
  final usecase = GetMyOrdersUseCase(ref.read(_orderRepositoryProvider));
  return MyOrdersNotifier(usecase);
});

class MyOrdersNotifier extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  final GetMyOrdersUseCase usecase;

  MyOrdersNotifier(this.usecase) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await usecase();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createOrderUsecaseProvider = Provider<CreateOrderUseCase>((ref) {
  return CreateOrderUseCase(ref.read(_orderRepositoryProvider));
});
