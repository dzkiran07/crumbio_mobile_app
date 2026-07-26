import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../constants/hive_table_constants.dart';
import '../../../features/marketplace/data/models/product/product_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  //init
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);
    _registerAdapter();
    await openBoxes();
  }

  //Register Adapters
  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.productTypeId)) {
      Hive.registerAdapter(ProductHiveModelAdapter());
    }
  }

  //Open Boxes
  Future<void> openBoxes() async {
    await Hive.openBox<ProductHiveModel>(HiveTableConstant.productTable);
    await Hive.openBox(HiveTableConstant.sessionTable);
  }

  //Close Boxes
  Future<void> close() async {
    await Hive.close();
  }

  //==========Product queries==================

  Box<ProductHiveModel> get _productBox =>
      Hive.box<ProductHiveModel>(HiveTableConstant.productTable);

  Future<void> cacheProducts(List<ProductHiveModel> products) async {
    await _productBox.clear();
    for (final product in products) {
      await _productBox.put(product.id, product);
    }
  }

  List<ProductHiveModel> getCachedProducts() {
    return _productBox.values.toList();
  }

  ProductHiveModel? getCachedProduct(String id) {
    return _productBox.get(id);
  }

  Future<void> clearProducts() async {
    await _productBox.clear();
  }

  //==========Session queries==================

  Box get _sessionBox => Hive.box(HiveTableConstant.sessionTable);

  Future<void> saveCurrentUser(Map<String, dynamic> userJson) async {
    await _sessionBox.put('current_user', userJson);
  }

  Map<String, dynamic>? getCurrentUser() {
    final raw = _sessionBox.get('current_user');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> clearCurrentUser() async {
    await _sessionBox.delete('current_user');
  }
}
