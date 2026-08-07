import '../../models/product_model.dart';

abstract class IProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String id);
  Future<bool> saveProduct(ProductModel product);
  Future<bool> deleteProduct(String id);
}
