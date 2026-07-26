import '../../models/product/product_api_model.dart';
import '../../models/product/product_hive_model.dart';

abstract class ProductDatasource {
	Future<List<ProductApiModel>> fetchProducts();
	Future<void> cacheProducts(List<ProductHiveModel> products);
	List<ProductHiveModel> getCachedProducts();
}
