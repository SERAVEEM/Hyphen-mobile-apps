import 'package:flutter/foundation.dart';
import 'mock_products.dart';

class ProductManager extends ChangeNotifier {
  // Singleton instance
  static final ProductManager _instance = ProductManager._internal();
  factory ProductManager() => _instance;

  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  ProductManager._internal() {
    // Seed initial mock products
    _products.addAll(mockProducts);
  }

  void addProduct(Product product) {
    _products.insert(0, product); // Insert new products at the top
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
