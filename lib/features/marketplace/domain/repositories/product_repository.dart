import '../entities/product_entity.dart';
import '../entities/product_variant.dart';

abstract class ProductRepository {
	Future<List<ProductEntity>> getProducts({String? category, String? baker, String? search});

	Future<ProductEntity> createProduct({
		required String name,
		required String description,
		required String category,
		required double basePrice,
		required List<ProductVariant> variants,
	});

	Future<ProductEntity> updateProduct({
		required String id,
		String? name,
		String? description,
		String? category,
		double? basePrice,
		List<ProductVariant>? variants,
		String? availability,
	});

	Future<void> deleteProduct(String id);

	Future<String> uploadProductImage({required String id, required String filePath});
}
