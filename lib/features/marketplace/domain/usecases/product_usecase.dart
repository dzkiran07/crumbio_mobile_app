import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
	final ProductRepository repository;

	GetProductsUseCase(this.repository);

	Future<List<ProductEntity>> call({String? category, String? search}) async {
		return await repository.getProducts(category: category, search: search);
	}
}
