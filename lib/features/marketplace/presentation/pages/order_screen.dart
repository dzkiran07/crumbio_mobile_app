import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/presentation/view_model/auth_view_model.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/state/order_provider.dart';

const List<_OrderFilterOption> _orderFilterOptions = [
  _OrderFilterOption(value: 'all', label: 'All'),
  _OrderFilterOption(value: 'pending', label: 'Pending'),
  _OrderFilterOption(value: 'baking', label: 'Baking'),
  _OrderFilterOption(value: 'ready', label: 'Ready'),
  _OrderFilterOption(value: 'picked_up', label: 'Picked up'),
  _OrderFilterOption(value: 'delivered', label: 'Delivered'),
  _OrderFilterOption(value: 'cancelled', label: 'Cancelled'),
];

class OrderScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStartShopping;

  const OrderScreen({super.key, this.onStartShopping});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
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

  Widget _buildEmptyState({required String title, required String subtitle, bool showLogin = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          if (showLogin)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bakeryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            )
          else if (widget.onStartShopping != null)
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
    );
  }

  Widget _buildOrderCard(OrderEntity order) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardBackground = isDarkMode ? const Color(0xFF241D17) : Colors.white;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFEDE3D6);
    final itemsSummary = order.items
        .map((item) => '${item.quantity}x ${item.productName}')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(order.id.length - 6).toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(itemsSummary, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.fulfillmentType == 'delivery' ? 'Delivery' : 'Pickup',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                'Rs ${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: bakeryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoggedIn = authState.status == AuthStatus.authenticated;
    final ordersAsync = isLoggedIn ? ref.watch(myOrdersProvider) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusFilterRow(),
              const SizedBox(height: 16),
              Expanded(
                child: !isLoggedIn
                    ? _buildEmptyState(
                        title: "You're not logged in",
                        subtitle: 'Login to view your orders.',
                        showLogin: true,
                      )
                    : ordersAsync!.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Error: $e')),
                        data: (orders) {
                          final filtered = _selectedStatus == 'all'
                              ? orders
                              : orders.where((o) => o.status == _selectedStatus).toList();
                          if (filtered.isEmpty) {
                            return _buildEmptyState(
                              title: 'No orders yet',
                              subtitle: 'Your placed orders will show up here.',
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () => ref.read(myOrdersProvider.notifier).fetchOrders(),
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _buildOrderCard(filtered[index]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD9782D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFD9782D),
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
