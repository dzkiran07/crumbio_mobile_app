import 'package:dio/dio.dart';

import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoint.dart';
import '../../../../domain/entities/product_variant.dart';
import '../../../models/product/product_api_model.dart';

class ProductRemoteDatasource {
	final ApiClient apiClient;

	ProductRemoteDatasource({required this.apiClient});

	String _extractErrorMessage(DioException e, String fallback) {
		final data = e.response?.data;
		if (data is Map<String, dynamic> && data['message'] is String) {
			return data['message'] as String;
		}
		return fallback;
	}

	List<Map<String, dynamic>> _variantsToJson(List<ProductVariant> variants) {
		return variants
				.map((v) => {
							'size': v.size,
							if (v.flavor != null) 'flavor': v.flavor,
							'price': v.price,
							'stock': v.stock,
						})
				.toList();
	}

	Future<List<ProductApiModel>> fetchProducts({String? category, String? baker, String? search}) async {
		final response = await apiClient.get(
			ApiEndpoints.products,
			queryParameters: {
				if (category != null && category.isNotEmpty) 'category': category,
				if (baker != null && baker.isNotEmpty) 'baker': baker,
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

	Future<ProductApiModel> createProduct({
		required String name,
		required String description,
		required String category,
		required double basePrice,
		required List<ProductVariant> variants,
	}) async {
		try {
			final response = await apiClient.post(
				ApiEndpoints.products,
				data: {
					'name': name,
					'description': description,
					'category': category,
					'basePrice': basePrice,
					'variants': _variantsToJson(variants),
				},
			);
			return ProductApiModel.fromJson(response.data as Map<String, dynamic>);
		} on DioException catch (e) {
			throw Exception(_extractErrorMessage(e, 'Could not create product'));
		}
	}

	Future<ProductApiModel> updateProduct({
		required String id,
		String? name,
		String? description,
		String? category,
		double? basePrice,
		List<ProductVariant>? variants,
		String? availability,
	}) async {
		try {
			final response = await apiClient.patch(
				ApiEndpoints.productById(id),
				data: {
					if (name != null) 'name': name,
					if (description != null) 'description': description,
					if (category != null) 'category': category,
					if (basePrice != null) 'basePrice': basePrice,
					if (variants != null) 'variants': _variantsToJson(variants),
					if (availability != null) 'availability': availability,
				},
			);
			return ProductApiModel.fromJson(response.data as Map<String, dynamic>);
		} on DioException catch (e) {
			throw Exception(_extractErrorMessage(e, 'Could not update product'));
		}
	}

	Future<void> deleteProduct(String id) async {
		try {
			await apiClient.delete(ApiEndpoints.productById(id));
		} on DioException catch (e) {
			throw Exception(_extractErrorMessage(e, 'Could not delete product'));
		}
	}

	Future<String> uploadProductImage({required String id, required String filePath}) async {
		try {
			final formData = FormData.fromMap({
				'image': await MultipartFile.fromFile(filePath),
			});
			final response = await apiClient.uploadFile(ApiEndpoints.productImage(id), formData: formData);
			return (response.data as Map<String, dynamic>)['imagePath'] as String;
		} on DioException catch (e) {
			throw Exception(_extractErrorMessage(e, 'Could not upload image'));
		}
	}
}
