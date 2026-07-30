import 'package:crumbio_mobile_app/core/api/api_endpoint.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

CartProduct _cartProduct({
  String id = 'p1',
  String name = 'Vanilla Cake',
  double price = 500,
  String size = 'Regular',
  String? flavor,
  int quantity = 1,
}) {
  return CartProduct(
    id: id,
    name: name,
    price: price,
    image: 'vanilla_cake.png',
    size: size,
    flavor: flavor,
    quantity: quantity,
  );
}

void main() {
  group('CartNotifier unit tests', () {
    test('1. addItem adds a new item and merges quantity on the same variant', () {
      final notifier = CartNotifier();

      notifier.addItem(_cartProduct(quantity: 1));
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.quantity, 1);

      notifier.addItem(_cartProduct(quantity: 2));
      expect(notifier.state, hasLength(1), reason: 'same id/size/flavor should merge, not duplicate');
      expect(notifier.state.first.quantity, 3);
    });

    test('2. incrementQuantity and decrementQuantity update quantity within bounds', () {
      final notifier = CartNotifier();
      notifier.addItem(_cartProduct(quantity: 1));
      final key = notifier.state.first.cartKey;

      notifier.incrementQuantity(key);
      expect(notifier.state.first.quantity, 2);

      notifier.decrementQuantity(key);
      notifier.decrementQuantity(key);
      expect(notifier.state.first.quantity, 1, reason: 'quantity should never drop below 1');
    });

    test('3. removeItem drops the matching entry and insertItem restores it (undo)', () {
      final notifier = CartNotifier();
      notifier.addItem(_cartProduct());
      final removed = notifier.state.first;

      notifier.removeItem(removed.cartKey);
      expect(notifier.state, isEmpty);

      notifier.insertItem(0, removed);
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.cartKey, removed.cartKey);
    });
  });

  group('ApiEndpoints.resolveMediaUrl unit tests', () {
    test('4. rewrites a bare uploads-relative path to an absolute server URL', () {
      final result = ApiEndpoints.resolveMediaUrl('uploads/products/croissant.png');

      expect(result, '${ApiEndpoints.serverUrl}/uploads/products/croissant.png');
    });
  });
}
