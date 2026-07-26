import 'package:hive/hive.dart';

import '../../../../../../core/constants/hive_table_constants.dart';
import '../../../models/product/product_hive_model.dart';

class ProductLocalDatasource {
	Box<ProductHiveModel> get _productBox =>
			Hive.box<ProductHiveModel>(HiveTableConstant.productTable);

	Future<void> cacheProducts(List<ProductHiveModel> products) async {
		await _productBox.clear();
		for (var product in products) {
			await _productBox.put(product.id, product);
		}
	}

	List<ProductHiveModel> getCachedProducts() {
		return _productBox.values.toList();
	}
}
