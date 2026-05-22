import 'package:flutter/foundation.dart';
import 'mock_products.dart';

class CartItem {
  final Product product;
  int quantity;
  String size;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.size,
  });
}

class CartManager extends ChangeNotifier {
  // Singleton instance
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  void addItem(Product product, {required String size, int quantity = 1}) {
    // Check if the product with exact same size is already in cart
    final index = _items.indexWhere(
      (item) => item.product.id == product.id && item.size == size,
    );

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, size: size, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(String productId, String size) {
    _items.removeWhere((item) => item.product.id == productId && item.size == size);
    notifyListeners();
  }

  void updateQuantity(String productId, String size, int quantity) {
    if (quantity <= 0) {
      removeItem(productId, size);
      return;
    }
    final index = _items.indexWhere(
      (item) => item.product.id == productId && item.size == size,
    );
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
