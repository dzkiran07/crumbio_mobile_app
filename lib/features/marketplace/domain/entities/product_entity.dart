import 'product_variant.dart';

class ProductEntity {
	final String id;
	final String name;
	final double basePrice;
	final String image;
	final String category;
	final String description;
	final String bakerName;
	final String availability;
	final List<ProductVariant> variants;

	ProductEntity({
		required this.id,
		required this.name,
		required this.basePrice,
		required this.image,
		required this.category,
		required this.description,
		required this.bakerName,
		required this.availability,
		this.variants = const [],
	});
}
