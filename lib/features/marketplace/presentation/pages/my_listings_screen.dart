import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_endpoint.dart';
import '../../domain/entities/product_entity.dart';
import '../state/my_listings_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  static const bakeryColor = Color(0xFFD9782D);

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('This removes "${product.name}" from your listings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(myListingsProvider.notifier).deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: navigate to the create-product form once it's built.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add product form coming next.')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myListingsProvider.notifier).fetchMyProducts(),
        child: listingsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "You haven't listed any products yet.\nTap + to add your first one.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: product.image.isNotEmpty
                            ? Image.network(
                                ApiEndpoints.resolveMediaUrl(product.image),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.bakery_dining_outlined),
                              )
                            : Container(
                                color: const Color(0xFFF2EBE0),
                                child: const Icon(
                                  Icons.bakery_dining_outlined,
                                  color: bakeryColor,
                                ),
                              ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.category} · Rs ${product.basePrice.toStringAsFixed(0)} · ${product.availability}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            // TODO: navigate to the edit-product form once it's built.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit product form coming next.')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
