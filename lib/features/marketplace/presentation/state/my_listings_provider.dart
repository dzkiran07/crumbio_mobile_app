import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/view_model/auth_view_model.dart';
import '../../data/datasources/product/local/product_local_datasource.dart';
import '../../data/datasources/product/remote/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/product_usecase.dart';

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, AsyncValue<List<ProductEntity>>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final remote = ProductRemoteDatasource(apiClient: apiClient);
  final local = ProductLocalDatasource();
  final repo = ProductRepositoryImpl(remoteDatasource: remote, localDatasource: local);
  final bakerId = ref.watch(authViewModelProvider).authEntity?.id;
  return MyListingsNotifier(
    getProductsUsecase: GetProductsUseCase(repo),
    deleteProductUsecase: DeleteProductUseCase(repo),
    bakerId: bakerId,
  );
});

class MyListingsNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  final GetProductsUseCase getProductsUsecase;
  final DeleteProductUseCase deleteProductUsecase;
  final String? bakerId;

  MyListingsNotifier({
    required this.getProductsUsecase,
    required this.deleteProductUsecase,
    required this.bakerId,
  }) : super(const AsyncValue.loading()) {
    fetchMyProducts();
  }

  Future<void> fetchMyProducts() async {
    final id = bakerId;
    if (id == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final products = await getProductsUsecase(baker: id);
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(String productId) async {
    await deleteProductUsecase(productId);
    await fetchMyProducts();
  }
}
