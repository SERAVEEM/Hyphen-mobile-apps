import 'package:flutter/foundation.dart';
import 'mock_products.dart';
import 'cart_manager.dart';

enum OrderStatus {
  processing,
  shipping,
  disputed,
}

class OrderItem {
  final String orderId;
  final Product product;
  final String size;
  final int quantity;
  final double price;
  final OrderStatus status;
  final DateTime orderDate;

  OrderItem({
    required this.orderId,
    required this.product,
    required this.size,
    required this.quantity,
    required this.price,
    required this.status,
    required this.orderDate,
  });
}

class OrderManager extends ChangeNotifier {
  // Singleton instance
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;

  final List<OrderItem> _orders = [];

  List<OrderItem> get orders => List.unmodifiable(_orders);

  OrderManager._internal() {
    // Seed initial mock orders based on the Figma "order history 1" image
    _orders.addAll([
      OrderItem(
        orderId: 'ORD-2023-8891',
        product: const Product(
          id: 'mock_ord_1',
          title: 'Structured Leather Tote',
          brand: 'Eleanor Vance',
          price: 250000,
          imageUrl: 'assets/images/cat_formal.png',
          size: 'M',
          condition: 'Sangat Baik',
          category: 'Formal',
        ),
        size: 'M',
        quantity: 1,
        price: 250000,
        status: OrderStatus.processing,
        orderDate: DateTime(2026, 5, 20, 10, 30),
      ),
      OrderItem(
        orderId: 'ORD-2023-8890',
        product: const Product(
          id: 'mock_ord_2',
          title: 'Oversized Poplin Shirt',
          brand: 'Julian Crain',
          price: 750000,
          imageUrl: 'assets/images/PreFall.png',
          size: 'L',
          condition: 'Sangat Baik',
          category: 'Daily',
        ),
        size: 'L',
        quantity: 1,
        price: 750000,
        status: OrderStatus.shipping,
        orderDate: DateTime(2026, 5, 19, 14, 15),
      ),
      OrderItem(
        orderId: 'ORD-2023-8890',
        product: const Product(
          id: 'mock_ord_3',
          title: 'Oversized Poplin Shirt',
          brand: 'Julian Crain',
          price: 750000,
          imageUrl: 'assets/images/PreFall.png',
          size: 'L',
          condition: 'Sangat Baik',
          category: 'Daily',
        ),
        size: 'L',
        quantity: 1,
        price: 750000,
        status: OrderStatus.shipping,
        orderDate: DateTime(2026, 5, 19, 14, 15),
      ),
      OrderItem(
        orderId: 'ORD-2023-8889',
        product: const Product(
          id: 'mock_ord_4',
          title: 'Leather Jacket',
          brand: 'Sarah Connor',
          price: 1250000,
          imageUrl: 'assets/images/jacket_product.png',
          size: 'M',
          condition: 'Sangat Baik',
          category: 'Daily',
        ),
        size: 'M',
        quantity: 1,
        price: 1250000,
        status: OrderStatus.disputed,
        orderDate: DateTime(2026, 5, 18, 11, 0),
      ),
      OrderItem(
        orderId: 'ORD-2023-8888',
        product: const Product(
          id: 'mock_ord_5',
          title: 'Classic Wool Trench Coat',
          brand: 'Arthur Pendragon',
          price: 5000000,
          imageUrl: 'assets/images/cat_daily.png',
          size: 'XL',
          condition: 'Sangat Baik',
          category: 'Formal',
        ),
        size: 'XL',
        quantity: 1,
        price: 5000000,
        status: OrderStatus.disputed,
        orderDate: DateTime(2026, 5, 17, 9, 30),
      ),
    ]);
  }

  void addOrderFromCheckout(String orderId, List<CartItem> items) {
    for (var item in items) {
      _orders.insert(
        0, // Insert at the top of the history list
        OrderItem(
          orderId: orderId,
          product: item.product,
          size: item.size,
          quantity: item.quantity,
          price: item.product.price,
          status: OrderStatus.processing, // Default status is processing
          orderDate: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    for (int i = 0; i < _orders.length; i++) {
      if (_orders[i].orderId == orderId) {
        _orders[i] = OrderItem(
          orderId: _orders[i].orderId,
          product: _orders[i].product,
          size: _orders[i].size,
          quantity: _orders[i].quantity,
          price: _orders[i].price,
          status: status,
          orderDate: _orders[i].orderDate,
        );
      }
    }
    notifyListeners();
  }
}
