import '../datasources/product/local/product_local_datasource.dart';
import '../datasources/product/remote/product_remote_datasource.dart';
import '../models/product/product_hive_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
	final ProductRemoteDatasource remoteDatasource;
	final ProductLocalDatasource localDatasource;

	ProductRepositoryImpl({
		required this.remoteDatasource,
		required this.localDatasource,
	});

	@override
	Future<List<ProductEntity>> getProducts({String? category, String? search}) async {
		final isUnfiltered = category == null && search == null;
		try {
			final remoteProducts = await remoteDatasource.fetchProducts(category: category, search: search);
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
			return remoteProducts
				.map((e) => ProductEntity(
					  id: e.id,
					  name: e.name,
					  basePrice: e.basePrice,
					  image: e.image,
					  category: e.category,
					  description: e.description,
					  bakerName: e.bakerName,
					  availability: e.availability,
					  variants: e.variants,
					))
				.toList();
		} catch (e) {
			// On error, fallback to local cache — only meaningful for the
			// unfiltered browse list, since filtered queries were never cached.
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
}
