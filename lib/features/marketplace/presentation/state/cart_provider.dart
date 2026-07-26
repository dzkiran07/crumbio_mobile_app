import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: unlike AgriBridge's CartNotifier, this doesn't persist the cart per
// logged-in user yet — that needs a full UserSessionService (getCurrentUserId,
// getCartForUser/saveCartForUser) which only exists once the auth feature is
// built. In-memory only for now.
final cartProvider = StateNotifierProvider<CartNotifier, List<CartProduct>>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<List<CartProduct>> {
  CartNotifier() : super(const []);

  void clear() {
    state = const [];
  }

  String _itemKey(CartProduct item) {
    return '${item.id}_${item.size}_${item.flavor ?? ''}';
  }

  void addItem(CartProduct newItem) {
    final newItemKey = _itemKey(newItem);
    final existingIndex = state.indexWhere(
      (item) => _itemKey(item) == newItemKey,
    );
    if (existingIndex == -1) {
      state = [...state, newItem];
      return;
    }

    final existing = state[existingIndex];
    final updatedItem = existing.copyWith(
      quantity: existing.quantity + newItem.quantity,
    );
    final updatedState = [...state];
    updatedState[existingIndex] = updatedItem;
    state = updatedState;
  }

  void incrementQuantity(String itemKey) {
    final index = state.indexWhere((item) => _itemKey(item) == itemKey);
    if (index == -1) return;

    final updatedState = [...state];
    final item = updatedState[index];
    updatedState[index] = item.copyWith(quantity: item.quantity + 1);
    state = updatedState;
  }

  void decrementQuantity(String itemKey) {
    final index = state.indexWhere((item) => _itemKey(item) == itemKey);
    if (index == -1) return;

    final updatedState = [...state];
    final item = updatedState[index];
    if (item.quantity <= 1) return;

    updatedState[index] = item.copyWith(quantity: item.quantity - 1);
    state = updatedState;
  }

  void removeItem(String itemKey) {
    state = state.where((item) => _itemKey(item) != itemKey).toList();
  }
}

class CartProduct {
  final String id;
  final String name;
  final double price;
  final String image;
  final String size;
  final String? flavor;
  final int quantity;

  const CartProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.size,
    this.flavor,
    required this.quantity,
  });

  CartProduct copyWith({
    String? id,
    String? name,
    double? price,
    String? image,
    String? size,
    String? flavor,
    int? quantity,
  }) {
    return CartProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      size: size ?? this.size,
      flavor: flavor ?? this.flavor,
      quantity: quantity ?? this.quantity,
    );
  }
}
