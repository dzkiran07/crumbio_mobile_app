import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const CartScreen({super.key, this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return CartScreenBody(onStartShopping: onStartShopping);
  }
}

class CartScreenBody extends ConsumerStatefulWidget {
  final VoidCallback? onStartShopping;

  const CartScreenBody({super.key, this.onStartShopping});

  @override
  ConsumerState<CartScreenBody> createState() => _CartScreenBodyState();
}

class _CartScreenBodyState extends ConsumerState<CartScreenBody> {
  static const int deliveryCharge = 60;

  double _subtotal(List<CartProduct> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  int _activeDeliveryCharge(List<CartProduct> cartItems) {
    return cartItems.isEmpty ? 0 : deliveryCharge;
  }

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  void _onProceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = _subtotal(cartItems);
    final activeDeliveryCharge = _activeDeliveryCharge(cartItems);
    final total = subtotal + activeDeliveryCharge;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final gradientTop = isDarkMode ? const Color(0xFF1A140F) : BakeryPalette.pageTop;
    final gradientBottom = isDarkMode
        ? const Color(0xFF231A12)
        : BakeryPalette.pageBottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientTop, gradientBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: cartItems.isEmpty
                    ? _buildEmptyState()
                    : _buildCartList(cartItems),
              ),
              if (cartItems.isNotEmpty)
                _buildSummaryCard(
                  cartItems: cartItems,
                  subtotal: subtotal,
                  activeDeliveryCharge: activeDeliveryCharge,
                  total: total,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartList(List<CartProduct> cartItems) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Dismissible(
          key: ValueKey(item.cartKey),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            final removedItem = item;
            final removedIndex = index;
            ref.read(cartProvider.notifier).removeItem(removedItem.cartKey);

            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            final snackBarController = messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                backgroundColor: isDarkMode
                    ? const Color(0xFF2E241B)
                    : const Color(0xFFFFF3E0),
                content: Text(
                  '${removedItem.name} removed from cart',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFECE0D3)
                        : const Color(0xFF8A5A22),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: isDarkMode
                      ? const Color(0xFFE0A98E)
                      : const Color(0xFFB35A1F),
                  onPressed: () {
                    ref
                        .read(cartProvider.notifier)
                        .insertItem(removedIndex, removedItem);
                  },
                ),
              ),
            );

            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                snackBarController.close();
              }
            });
          },
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 6),
                Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: CartItemCard(
            item: item,
            onAdd: () =>
                ref.read(cartProvider.notifier).incrementQuantity(item.cartKey),
            onRemove: () =>
                ref.read(cartProvider.notifier).decrementQuantity(item.cartKey),
            formatPrice: _formatPrice,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF4B5563);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFEDEFF2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 42,
              color: isDarkMode ? Colors.white60 : const Color(0xFF9FA6B2),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add some fresh bakes to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 18,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onStartShopping ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: BakeryPalette.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start Shopping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required List<CartProduct> cartItems,
    required double subtotal,
    required int activeDeliveryCharge,
    required double total,
  }) {
    final bool isEmpty = cartItems.isEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? colorScheme.surface : Colors.white;
    final borderColor = isDarkMode ? Colors.white12 : BakeryPalette.softBorder;
    final softRowBg = isDarkMode ? const Color(0xFF2B241E) : BakeryPalette.softOrange;
    final totalLabelColor = isDarkMode ? Colors.white : BakeryPalette.darkOrange;
    final totalValueColor = isDarkMode
        ? const Color(0xFFE0A98E)
        : BakeryPalette.primaryOrange;
    final buttonBg = BakeryPalette.primaryOrange;
    const buttonFg = Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : BakeryPalette.primaryOrange)
                  .withValues(alpha: isDarkMode ? 0.25 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: softRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cartItems.length} item${cartItems.length > 1 ? 's' : ''} selected',
                style: TextStyle(
                  color: totalLabelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              label: 'Subtotal',
              value: 'Rs ${_formatPrice(subtotal)}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Delivery Charge',
              value: 'Rs ${_formatPrice(activeDeliveryCharge.toDouble())}',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: totalLabelColor,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    'Rs ${_formatPrice(total)}',
                    key: ValueKey(total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: totalValueColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isEmpty ? null : _onProceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  disabledBackgroundColor: isDarkMode
                      ? const Color(0xFF6B5A46)
                      : const Color(0xFFE6C9A8),
                  foregroundColor: buttonFg,
                  disabledForegroundColor: isDarkMode
                      ? Colors.white60
                      : const Color(0xFF9E8368),
                  elevation: isEmpty ? 0 : 2,
                  shadowColor: buttonBg.withValues(alpha: isDarkMode ? 0.12 : 0.35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Proceed To Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartProduct item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final String Function(double value) formatPrice;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.formatPrice,
  });

  Widget _buildImageFallback(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF2B241E) : BakeryPalette.softOrange,
      child: Icon(
        Icons.bakery_dining_outlined,
        color: isDarkMode ? Colors.white60 : BakeryPalette.darkOrange,
      ),
    );
  }

  Widget _buildItemImage(BuildContext context) {
    final image = item.image.trim();
    if (image.isEmpty) return _buildImageFallback(context);

    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
    );
  }

  String get _variantLabel {
    if (item.flavor != null && item.flavor!.isNotEmpty) {
      return '${item.size} - ${item.flavor}';
    }
    return item.size;
  }

  @override
  Widget build(BuildContext context) {
    final double itemTotal = item.price * item.quantity;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDarkMode ? Colors.white12 : BakeryPalette.softBorder;
    final titleColor = isDarkMode ? Colors.white : BakeryPalette.darkOrange;
    final itemPriceChipBg = isDarkMode
        ? const Color(0xFF2B241E)
        : BakeryPalette.softOrange;
    final itemPriceColor = isDarkMode
        ? const Color(0xFFE0A98E)
        : BakeryPalette.primaryOrange;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : BakeryPalette.primaryOrange).withValues(
              alpha: isDarkMode ? 0.26 : 0.07,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 76, height: 76, child: _buildItemImage(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: itemPriceChipBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_variantLabel · Rs ${formatPrice(item.price)}',
                    style: TextStyle(
                      color: itemPriceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: Rs ${formatPrice(itemTotal)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2B241E) : BakeryPalette.pageTop,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityActionButton(icon: Icons.remove, onTap: onRemove),
                SizedBox(
                  width: 34,
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
                _QuantityActionButton(icon: Icons.add, onTap: onAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: isDarkMode ? const Color(0xFFE0A98E) : BakeryPalette.primaryOrange,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDarkMode ? Colors.white70 : BakeryPalette.textMuted;
    final valueColor = isDarkMode ? Colors.white : BakeryPalette.darkOrange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class BakeryPalette {
  static const Color primaryOrange = Color(0xFFD9782D);
  static const Color darkOrange = Color(0xFF8A5A22);
  static const Color softOrange = Color(0xFFFBEADA);
  static const Color softBorder = Color(0xFFEFE0D0);
  static const Color pageTop = Color(0xFFFFFFFF);
  static const Color pageBottom = Color(0xFFFDF6EE);
  static const Color textMuted = Color(0xFF8A7A65);
}
