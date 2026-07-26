class ProductApiModel {
	final String id;
	final String name;
	final double basePrice;
	final String image;
	final String category;
	final String description;
	final String bakerName;
	final String availability;

	ProductApiModel({
		required this.id,
		required this.name,
		required this.basePrice,
		required this.image,
		required this.category,
		required this.description,
		required this.bakerName,
		required this.availability,
	});

	factory ProductApiModel.fromJson(Map<String, dynamic> json) {
		final images = json['images'] as List<dynamic>? ?? [];
		return ProductApiModel(
			id: json['_id'] ?? '',
			name: json['name'] ?? '',
			basePrice: (json['basePrice'] is int)
				? (json['basePrice'] as int).toDouble()
				: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
			image: images.isNotEmpty ? images.first as String : '',
			category: json['category'] ?? '',
			description: (json['description'] as String?)?.isNotEmpty == true ? json['description'] : 'No description available.',
			bakerName: (json['bakerName'] as String?)?.isNotEmpty == true ? json['bakerName'] : 'Unknown baker',
			availability: (json['availability'] as String?)?.isNotEmpty == true ? json['availability'] : 'available',
		);
	}
}
