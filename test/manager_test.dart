import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen/product_manager.dart';
import 'package:hyphen/order_manager.dart';
import 'package:hyphen/mock_products.dart';

void main() {
  group('ProductManager Tests', () {
    late ProductManager productManager;

    setUp(() {
      productManager = ProductManager();
    });

    test('Initial seeding test', () {
      expect(productManager.products.isNotEmpty, true);
    });

    test('Add Product test', () {
      final initialCount = productManager.products.length;
      final testProduct = Product(
        id: 'test_product_123',
        title: 'Test Hoodie',
        brand: 'Alex Rivera',
        price: 350000,
        imageUrl: 'assets/images/cat_daily.png',
        size: 'L',
        condition: 'Sangat Baik',
        category: 'Daily',
      );

      productManager.addProduct(testProduct);

      expect(productManager.products.length, initialCount + 1);
      expect(productManager.products.first.id, 'test_product_123');
      expect(productManager.products.first.title, 'Test Hoodie');
      
      // Clean up for other tests
      productManager.deleteProduct('test_product_123');
    });

    test('Update Product test', () {
      final testProduct = Product(
        id: 'test_product_update',
        title: 'Old Title',
        brand: 'Alex Rivera',
        price: 350000,
        imageUrl: 'assets/images/cat_daily.png',
        size: 'L',
        condition: 'Sangat Baik',
        category: 'Daily',
      );

      productManager.addProduct(testProduct);

      final updatedProduct = Product(
        id: 'test_product_update',
        title: 'New Title',
        brand: 'Alex Rivera',
        price: 400000,
        imageUrl: 'assets/images/cat_daily.png',
        size: 'XL',
        condition: 'Baik',
        category: 'Daily',
      );

      productManager.updateProduct(updatedProduct);

      final found = productManager.products.firstWhere((p) => p.id == 'test_product_update');
      expect(found.title, 'New Title');
      expect(found.price, 400000);
      expect(found.size, 'XL');
      expect(found.condition, 'Baik');

      // Clean up
      productManager.deleteProduct('test_product_update');
    });

    test('Delete Product test', () {
      final testProduct = Product(
        id: 'test_product_delete',
        title: 'Delete Me',
        brand: 'Alex Rivera',
        price: 350000,
        imageUrl: 'assets/images/cat_daily.png',
        size: 'L',
        condition: 'Sangat Baik',
        category: 'Daily',
      );

      productManager.addProduct(testProduct);
      expect(productManager.products.any((p) => p.id == 'test_product_delete'), true);

      productManager.deleteProduct('test_product_delete');
      expect(productManager.products.any((p) => p.id == 'test_product_delete'), false);
    });

    test('Product verification flow test', () {
      // 1. Create a new product which starts as unverified (isVerified: false)
      final newProduct = Product(
        id: 'verification_test_prod',
        title: 'Verification Test Hoodie',
        brand: 'Alex Rivera',
        price: 250000,
        imageUrl: 'assets/images/cat_daily.png',
        size: 'M',
        condition: 'Sangat Baik',
        category: 'Daily',
        isVerified: false,
      );

      // Add to ProductManager
      productManager.addProduct(newProduct);

      // Verify that the product is indeed in the list but isVerified is false
      final addedProduct = productManager.products.firstWhere((p) => p.id == 'verification_test_prod');
      expect(addedProduct.isVerified, false);

      // Verify that the home feed filter (only verified) omits this product
      final homeFeedList = productManager.products.where((p) => p.isVerified).toList();
      expect(homeFeedList.any((p) => p.id == 'verification_test_prod'), false);

      // Verify that the search filter (only verified) omits this product
      final searchList = productManager.products.where((p) => p.isVerified).toList();
      expect(searchList.any((p) => p.id == 'verification_test_prod'), false);

      // 2. Approve/Verify the product in the verification queue
      final verifiedProduct = addedProduct.copyWith(isVerified: true);
      productManager.updateProduct(verifiedProduct);

      // Verify that isVerified is now true
      final updatedProduct = productManager.products.firstWhere((p) => p.id == 'verification_test_prod');
      expect(updatedProduct.isVerified, true);

      // Verify that it is now included in the home feed list (verified products)
      final homeFeedListAfter = productManager.products.where((p) => p.isVerified).toList();
      expect(homeFeedListAfter.any((p) => p.id == 'verification_test_prod'), true);

      // Verify that it is now included in the search list (verified products)
      final searchListAfter = productManager.products.where((p) => p.isVerified).toList();
      expect(searchListAfter.any((p) => p.id == 'verification_test_prod'), true);

      // Clean up
      productManager.deleteProduct('verification_test_prod');
    });
  });

  group('OrderManager Tests', () {
    late OrderManager orderManager;

    setUp(() {
      orderManager = OrderManager();
    });

    test('Initial seeding test', () {
      expect(orderManager.orders.isNotEmpty, true);
    });

    test('Update Order Status test', () {
      // Find a processing order or create one
      final testOrderId = 'ORD-2023-8891';
      final order = orderManager.orders.firstWhere((o) => o.orderId == testOrderId);
      expect(order.status, OrderStatus.processing);

      // Update to shipping
      orderManager.updateOrderStatus(testOrderId, OrderStatus.shipping);
      
      final updatedOrder = orderManager.orders.firstWhere((o) => o.orderId == testOrderId);
      expect(updatedOrder.status, OrderStatus.shipping);

      // Revert status back
      orderManager.updateOrderStatus(testOrderId, OrderStatus.processing);
      expect(orderManager.orders.firstWhere((o) => o.orderId == testOrderId).status, OrderStatus.processing);
    });
  });
}
