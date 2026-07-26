import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/cart_provider.dart';
import 'cart_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const int deliveryCharge = 60;

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _pickupNoteController = TextEditingController();

  String _fulfillmentType = 'pickup';
  String _paymentMethod = 'cash_on_delivery';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _pickupNoteController.dispose();
    super.dispose();
  }

  double _subtotal(List<CartProduct> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  double get _deliveryFee => _fulfillmentType == 'delivery' ? deliveryCharge.toDouble() : 0;

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  InputDecoration _inputDecoration({required String hintText}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.white54 : const Color(0xFF98A2B3),
      ),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFF1F3F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.white24 : const Color(0xFFD0D5DD),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BakeryPalette.primaryOrange,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.2),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    // TODO: wire to POST /orders once the auth feature exists — placing a
    // real order needs a logged-in buyer's JWT, which we don't have yet.
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Placing orders coming next — needs login.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = _subtotal(cartItems);
    final total = subtotal + _deliveryFee;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final labelColor = isDarkMode ? Colors.white70 : const Color(0xFF344054);
    final summaryBgColor = isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFF1F3F6);
    final summaryBorder = isDarkMode ? Colors.white24 : const Color(0xFFD0D5DD);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fulfillment',
                  style: TextStyle(fontSize: 15, color: labelColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'pickup',
                      label: Text('Pickup'),
                      icon: Icon(Icons.storefront_outlined),
                    ),
                    ButtonSegment(
                      value: 'delivery',
                      label: Text('Delivery'),
                      icon: Icon(Icons.delivery_dining_outlined),
                    ),
                  ],
                  selected: {_fulfillmentType},
                  onSelectionChanged: (selection) {
                    setState(() => _fulfillmentType = selection.first);
                  },
                ),
                const SizedBox(height: 18),
                if (_fulfillmentType == 'delivery') ...[
                  Text(
                    'Delivery Address *',
                    style: TextStyle(fontSize: 15, color: labelColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    keyboardType: TextInputType.streetAddress,
                    minLines: 3,
                    maxLines: 4,
                    decoration: _inputDecoration(hintText: 'Enter your complete delivery address'),
                    validator: (value) {
                      if (_fulfillmentType != 'delivery') return null;
                      final trimmed = (value ?? '').trim();
                      if (trimmed.isEmpty) return 'Delivery address is required';
                      return null;
                    },
                  ),
                ] else ...[
                  Text(
                    'Pickup Note (optional)',
                    style: TextStyle(fontSize: 15, color: labelColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pickupNoteController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: _inputDecoration(hintText: 'e.g. pickup after 5pm'),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Payment method',
                  style: TextStyle(fontSize: 15, color: labelColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _paymentChip('cash_on_delivery', 'Cash on delivery', Icons.payments_outlined),
                    _paymentChip('khalti', 'Khalti', Icons.account_balance_wallet_outlined),
                    _paymentChip('esewa', 'eSewa', Icons.account_balance_wallet_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: summaryBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: summaryBorder),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Subtotal', value: 'Rs ${_formatPrice(subtotal)}'),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Delivery Fee',
                        value: 'Rs ${_formatPrice(_deliveryFee)}',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: summaryBorder, height: 1),
                      ),
                      _SummaryRow(label: 'Total', value: 'Rs ${_formatPrice(total)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BakeryPalette.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (_) => setState(() => _paymentMethod = value),
      selectedColor: BakeryPalette.primaryOrange,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
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
        Text(label, style: TextStyle(fontSize: 15, color: labelColor, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 15, color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
