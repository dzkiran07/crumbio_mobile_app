import '../datasources/product/local/product_local_datasource.dart';
import '../datasources/product/remote/product_remote_datasource.dart';
import '../models/product/product_api_model.dart';
import '../models/product/product_hive_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
	final ProductRemoteDatasource remoteDatasource;
	final ProductLocalDatasource localDatasource;

	ProductRepositoryImpl({
		required this.remoteDatasource,
		required this.localDatasource,
	});

	ProductEntity _toEntity(ProductApiModel e) {
		return ProductEntity(
			id: e.id,
			name: e.name,
			basePrice: e.basePrice,
			image: e.image,
			category: e.category,
			description: e.description,
			bakerName: e.bakerName,
			availability: e.availability,
			variants: e.variants,
		);
	}

	@override
	Future<List<ProductEntity>> getProducts({String? category, String? baker, String? search}) async {
		final isUnfiltered = category == null && baker == null && search == null;
		try {
			final remoteProducts = await remoteDatasource.fetchProducts(
				category: category,
				baker: baker,
				search: search,
			);
			if (isUnfiltered) {
				final hiveModels = remoteProducts.map((e) => ProductHiveModel(
					id: e.id,
					name: e.name,
					basePrice: e.basePrice,
					image: e.image,
					category: e.category,
					description: e.description,
					bakerName: e.bakerName,
					availability: e.availability,
				)).toList();
				await localDatasource.cacheProducts(hiveModels);
			}
			return remoteProducts.map(_toEntity).toList();
		} catch (e) {
			// On error, fallback to local cache — only meaningful for the
			// unfiltered browse list, since filtered/my-listings queries were
			// never cached.
			if (!isUnfiltered) rethrow;
			final cached = localDatasource.getCachedProducts();
			return cached
				.map((e) => ProductEntity(
					  id: e.id,
					  name: e.name,
					  basePrice: e.basePrice,
					  image: e.image,
					  category: e.category,
					  description: e.description,
					  bakerName: e.bakerName,
					  availability: e.availability,
					))
				.toList();
		}
	}

	@override
	Future<ProductEntity> createProduct({
		required String name,
		required String description,
		required String category,
		required double basePrice,
		required List<ProductVariant> variants,
	}) async {
		final result = await remoteDatasource.createProduct(
			name: name,
			description: description,
			category: category,
			basePrice: basePrice,
			variants: variants,
		);
		return _toEntity(result);
	}

	@override
	Future<ProductEntity> updateProduct({
		required String id,
		String? name,
		String? description,
		String? category,
		double? basePrice,
		List<ProductVariant>? variants,
		String? availability,
	}) async {
		final result = await remoteDatasource.updateProduct(
			id: id,
			name: name,
			description: description,
			category: category,
			basePrice: basePrice,
			variants: variants,
			availability: availability,
		);
		return _toEntity(result);
	}

	@override
	Future<void> deleteProduct(String id) {
		return remoteDatasource.deleteProduct(id);
	}

	@override
	Future<String> uploadProductImage({required String id, required String filePath}) {
		return remoteDatasource.uploadProductImage(id: id, filePath: filePath);
	}
}
