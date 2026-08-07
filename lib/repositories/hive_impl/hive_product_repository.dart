import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/product_model.dart';
import '../interfaces/i_product_repository.dart';

class HiveProductRepository implements IProductRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final items = HiveService.getAll(AppConstants.productBoxName);
      if (items.isEmpty) {
        // Create default water product if box is empty
        final defaultProd = ProductModel(
          id: 'PROD-20L',
          name: '20L Water Can',
          price: AppConstants.defaultCanPrice,
          unit: '20L Can',
          description: 'Standard 20L Purified Water Jar',
        );
        await saveProduct(defaultProd);
        return [defaultProd];
      }
      return items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return ProductModel.fromJson(json);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final box = HiveService.getBox(AppConstants.productBoxName);
      final raw = box.get(id);
      if (raw == null) return null;
      return ProductModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> saveProduct(ProductModel product) async {
    final box = HiveService.getBox(AppConstants.productBoxName);
    final id = product.id.isEmpty
        ? 'PROD-${_uuid.v4().substring(0, 5).toUpperCase()}'
        : product.id;
    final updated = product.copyWith(id: id, updatedAt: DateTime.now());

    try {
      await box.put(id, jsonEncode(updated.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteProduct(String id) async {
    final box = HiveService.getBox(AppConstants.productBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
