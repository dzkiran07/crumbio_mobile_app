import 'package:hive_flutter/hive_flutter.dart';

import '../../constants/hive_table_constants.dart';

class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(HiveTableConstants.productCacheBox);
  }
}
