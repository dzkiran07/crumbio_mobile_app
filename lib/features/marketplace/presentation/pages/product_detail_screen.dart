import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_endpoint.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant.dart';
import '../state/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  bool get _isAvailable {
    if (widget.product.availability == 'sold_out' ||
        widget.product.availability == 'unlisted') {
      return false;
    }
    if (_selectedVariant != null) return _selectedVariant!.stock > 0;
    return true;
  }

  bool get _canIncreaseQty {
    if (!_isAvailable) return false;
    if (_selectedVariant != null) return _quantity < _selectedVariant!.stock;
    return true;
  }

  double get _unitPrice => _selectedVariant?.price ?? widget.product.basePrice;

  double get _totalPrice => _unitPrice * _quantity;

  void _increaseQty() {
    if (!_canIncreaseQty) return;
    setState(() => _quantity++);
  }

  void _decreaseQty() {
    if (_quantity == 1) return;
    setState(() => _quantity--);
  }

  void _selectVariant(ProductVariant variant) {
    setState(() {
      _selectedVariant = variant;
      _quantity = 1;
    });
  }

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _variantLabel(ProductVariant variant) {
    if (variant.flavor != null && variant.flavor!.isNotEmpty) {
      return '${variant.size} - ${variant.flavor}';
    }
    return variant.size;
  }

  void _onAddToCart() {
    if (!_isAvailable) return;

    ref.read(cartProvider.notifier).addItem(
          CartProduct(
            id: widget.product.id,
            name: widget.product.name,
            price: _unitPrice,
            image: widget.product.image,
            size: _selectedVariant?.size ?? '',
            flavor: _selectedVariant?.flavor,
            quantity: _quantity,
          ),
        );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            '${widget.product.name}'
            '${_selectedVariant != null ? ' (${_variantLabel(_selectedVariant!)})' : ''}'
            ' x$_quantity added to cart',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Widget _buildProductImage() {
    final image = widget.product.image.trim();
    if (image.isEmpty) {
      return _ImageFallback(name: widget.product.name);
    }

    return Image.network(
      ApiEndpoints.resolveMediaUrl(image),
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return _ImageFallback(name: widget.product.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final pageBackground = isDarkMode ? const Color(0xFF1A140F) : const Color(0xFFE8C39E);
    final detailBackground = isDarkMode ? theme.colorScheme.surface : Colors.white;
    final imagePanelBackground = isDarkMode
        ? const Color(0xFF2B241E)
        : const Color(0xFFF3DFC7);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF3B2412);
    final descriptionTitleColor = isDarkMode ? Colors.white : const Color(0xFF2E2015);
    final descriptionColor = isDarkMode ? Colors.white70 : const Color(0xFF6E6255);
    final backIconColor = isDarkMode ? Colors.white : Colors.black;
    final totalPriceColor = isDarkMode ? Colors.white : Colors.black;
    final ctaBg = isDarkMode ? const Color(0xFFD9782D) : Colors.white;
    final ctaFg = isDarkMode ? Colors.white : const Color(0xFFD9782D);
    final ctaDisabledBg = isDarkMode
        ? const Color(0xFF3A342E)
        : const Color(0xFFECE3D6);
    final ctaDisabledFg = isDarkMode
        ? Colors.white60
        : const Color(0xFF9E9385);

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  top: 320,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: detailBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(42),
                        bottomRight: Radius.circular(42),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 85, 24, 20),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 44,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.product.name,
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w800,
                                              color: titleColor,
                                              height: 1.05,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.product.bakerName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: descriptionColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _QtyStepper(
                                        quantity: _quantity,
                                        canDecrease: _quantity > 1 && _isAvailable,
                                        onDecrease: _decreaseQty,
                                        onIncrease: _increaseQty,
                                        canIncrease: _canIncreaseQty,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.product.variants.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    'Size / flavor',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: descriptionTitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: widget.product.variants.map((variant) {
                                      final isSelected = _selectedVariant == variant;
                                      final outOfStock = variant.stock <= 0;
                                      return ChoiceChip(
                                        label: Text(_variantLabel(variant)),
                                        selected: isSelected,
                                        onSelected: outOfStock
                                            ? null
                                            : (_) => _selectVariant(variant),
                                        selectedColor: const Color(0xFFD9782D),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : outOfStock
                                                  ? descriptionColor.withValues(alpha: 0.5)
                                                  : descriptionTitleColor,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    _InfoChip(
                                      text: 'Rs ${_formatPrice(_unitPrice)}',
                                      primary: true,
                                    ),
                                    const SizedBox(width: 10),
                                    _InfoChip(text: 'Qty $_quantity'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Product Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: descriptionTitleColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.product.description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: descriptionColor,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: imagePanelBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(56),
                      bottomRight: Radius.circular(56),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              size: 30,
                              color: backIconColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: _buildProductImage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
            decoration: BoxDecoration(color: pageBackground),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rs ${_formatPrice(_totalPrice)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: totalPriceColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isAvailable ? _onAddToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ctaBg,
                      disabledBackgroundColor: ctaDisabledBg,
                      foregroundColor: ctaFg,
                      disabledForegroundColor: ctaDisabledFg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _isAvailable ? 'Add to cart' : 'Out of stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QtyStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFFAF5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : const Color(0xFFEAE0D2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyIconButton(icon: Icons.remove, onTap: onDecrease, enabled: canDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white70 : const Color(0xFFB37F4F),
              ),
            ),
          ),
          _QtyIconButton(icon: Icons.add, onTap: onIncrease, enabled: canIncrease),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QtyIconButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          icon,
          size: 17,
          color: enabled
              ? (isDarkMode ? const Color(0xFFE0A98E) : const Color(0xFFD9782D))
              : (isDarkMode ? Colors.white24 : const Color(0xFFD6C6B0)),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final bool primary;

  const _InfoChip({required this.text, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chipBg = primary
        ? (isDarkMode ? const Color(0xFF3A2E22) : const Color(0xFFFBEADA))
        : (isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFF2EBE0));
    final chipFg = primary
        ? (isDarkMode ? const Color(0xFFE0A98E) : const Color(0xFFB35A1F))
        : (isDarkMode ? Colors.white70 : const Color(0xFF6E6255));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: chipFg),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String name;

  const _ImageFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFEFE3D2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bakery_dining_outlined,
              size: 34,
              color: isDarkMode ? Colors.white60 : const Color(0xFF9E7F5C),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : const Color(0xFF6E5A3F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
