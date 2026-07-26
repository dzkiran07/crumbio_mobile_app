import 'package:hive/hive.dart';

part 'product_hive_model.g.dart';

@HiveType(typeId: 0)
class ProductHiveModel extends HiveObject {
	@HiveField(0)
	String id;

	@HiveField(1)
	String name;

	@HiveField(2)
	double basePrice;

	@HiveField(3)
	String image;

	@HiveField(4)
	String category;

	@HiveField(5)
	String description;

	@HiveField(6)
	String bakerName;

	@HiveField(7)
	String availability;

	ProductHiveModel({
		required this.id,
		required this.name,
		required this.basePrice,
		required this.image,
		required this.category,
		required this.description,
		required this.bakerName,
		required this.availability,
	});

	factory ProductHiveModel.fromApiModel(dynamic apiModel) {
		return ProductHiveModel(
			id: apiModel.id,
			name: apiModel.name,
			basePrice: apiModel.basePrice,
			image: apiModel.image,
			category: apiModel.category,
			description: (apiModel.description != null && apiModel.description.isNotEmpty) ? apiModel.description : 'No description available.',
			bakerName: (apiModel.bakerName != null && apiModel.bakerName.isNotEmpty) ? apiModel.bakerName : 'Unknown baker',
			availability: (apiModel.availability != null && apiModel.availability.isNotEmpty) ? apiModel.availability : 'available',
		);
	}
}
