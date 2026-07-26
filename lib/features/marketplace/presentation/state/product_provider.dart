import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../../data/datasources/product/local/product_local_datasource.dart';
import '../../data/datasources/product/remote/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/product_usecase.dart';

final productProvider =
		StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductEntity>>>((ref) {
	final apiClient = ApiClient(userSessionService: UserSessionService());
	final remote = ProductRemoteDatasource(apiClient: apiClient);
	final local = ProductLocalDatasource();
	final repo = ProductRepositoryImpl(remoteDatasource: remote, localDatasource: local);
	final usecase = GetProductsUseCase(repo);
	return ProductNotifier(usecase);
});

class ProductNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
	final GetProductsUseCase usecase;

	ProductNotifier(this.usecase) : super(const AsyncValue.loading()) {
		fetchProducts();
	}

	Future<void> fetchProducts() async {
		state = const AsyncValue.loading();
		try {
			final products = await usecase();
			state = AsyncValue.data(products);
		} catch (e, st) {
			state = AsyncValue.error(e, st);
		}
	}
}
