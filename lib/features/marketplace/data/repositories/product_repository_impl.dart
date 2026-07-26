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
	Future<List<ProductEntity>> getProducts() async {
		try {
			final remoteProducts = await remoteDatasource.fetchProducts();
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
					))
				.toList();
		} catch (e) {
			// On error, fallback to local cache
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
