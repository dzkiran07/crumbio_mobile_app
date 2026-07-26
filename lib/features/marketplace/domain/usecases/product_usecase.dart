import '../entities/product_entity.dart';
import '../entities/product_variant.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
	final ProductRepository repository;

	GetProductsUseCase(this.repository);

	Future<List<ProductEntity>> call({String? category, String? baker, String? search}) async {
		return await repository.getProducts(category: category, baker: baker, search: search);
	}
}

class CreateProductUseCase {
	final ProductRepository repository;

	CreateProductUseCase(this.repository);

	Future<ProductEntity> call({
		required String name,
		required String description,
		required String category,
		required double basePrice,
		required List<ProductVariant> variants,
	}) async {
		return await repository.createProduct(
			name: name,
			description: description,
			category: category,
			basePrice: basePrice,
			variants: variants,
		);
	}
}

class UpdateProductUseCase {
	final ProductRepository repository;

	UpdateProductUseCase(this.repository);

	Future<ProductEntity> call({
		required String id,
		String? name,
		String? description,
		String? category,
		double? basePrice,
		List<ProductVariant>? variants,
		String? availability,
	}) async {
		return await repository.updateProduct(
			id: id,
			name: name,
			description: description,
			category: category,
			basePrice: basePrice,
			variants: variants,
			availability: availability,
		);
	}
}

class DeleteProductUseCase {
	final ProductRepository repository;

	DeleteProductUseCase(this.repository);

	Future<void> call(String id) async {
		return await repository.deleteProduct(id);
	}
}

class UploadProductImageUseCase {
	final ProductRepository repository;

	UploadProductImageUseCase(this.repository);

	Future<String> call({required String id, required String filePath}) async {
		return await repository.uploadProductImage(id: id, filePath: filePath);
	}
}
