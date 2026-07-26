import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoint.dart';
import '../../../models/product/product_api_model.dart';

class ProductRemoteDatasource {
	final ApiClient apiClient;

	ProductRemoteDatasource({required this.apiClient});

	Future<List<ProductApiModel>> fetchProducts({String? category, String? search}) async {
		final response = await apiClient.get(
			ApiEndpoints.products,
			queryParameters: {
				if (category != null && category.isNotEmpty) 'category': category,
				if (search != null && search.isNotEmpty) 'search': search,
			},
		);
		final data = response.data;
		if (data is List) {
			return data
					.map((item) => ProductApiModel.fromJson(item as Map<String, dynamic>))
					.toList();
		}
		throw Exception('Invalid response format for products');
	}
}
