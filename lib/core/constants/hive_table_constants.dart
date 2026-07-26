class HiveTableConstant {
  HiveTableConstant._();

  // Database name
  static const String dbName = 'crumbio_db';

  static const int productTypeId = 0;
  static const String productTable = 'product_table';

  // Untyped box — stores the cached logged-in user's profile JSON so the
  // app can restore session state on cold start without hitting GET /me.
  static const String sessionTable = 'session_table';
}
