class ProductVariant {
	final String size;
	final String? flavor;
	final double price;
	final int stock;

	ProductVariant({
		required this.size,
		this.flavor,
		required this.price,
		required this.stock,
	});
}
