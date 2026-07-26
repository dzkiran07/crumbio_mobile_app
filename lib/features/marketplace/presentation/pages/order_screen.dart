import 'package:flutter/material.dart';

// NOTE: this is a styled shell only — Crumbio doesn't have an Order
// domain/data layer in the frontend yet (entity, repository, GET /orders/mine
// wiring), so there's no real order data to show. That's its own step, sized
// similarly to how the Product feature was built. The status filter here
// already matches Crumbio's real backend order-status enum.
const List<_OrderFilterOption> _orderFilterOptions = [
  _OrderFilterOption(value: 'all', label: 'All'),
  _OrderFilterOption(value: 'pending', label: 'Pending'),
  _OrderFilterOption(value: 'baking', label: 'Baking'),
  _OrderFilterOption(value: 'ready', label: 'Ready'),
  _OrderFilterOption(value: 'picked_up', label: 'Picked up'),
  _OrderFilterOption(value: 'delivered', label: 'Delivered'),
  _OrderFilterOption(value: 'cancelled', label: 'Cancelled'),
];

class OrderScreen extends StatefulWidget {
  final VoidCallback? onStartShopping;

  const OrderScreen({super.key, this.onStartShopping});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  static const bakeryColor = Color(0xFFD9782D);

  String _selectedStatus = _orderFilterOptions.first.value;

  Widget _buildStatusFilterRow() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _orderFilterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _orderFilterOptions[index];
          final isSelected = filter.value == _selectedStatus;

          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = filter.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? bakeryColor
                    : (isDarkMode ? const Color(0xFF2B241E) : const Color(0xFFF2EBE0)),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.transparent,
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white70 : const Color(0xFF8A7A65)),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusFilterRow(),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Order tracking coming soon',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "This tab will show your real orders once order placement is wired up.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.onStartShopping != null)
                        ElevatedButton(
                          onPressed: widget.onStartShopping,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bakeryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Shopping'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderFilterOption {
  final String value;
  final String label;

  const _OrderFilterOption({required this.value, required this.label});
}
