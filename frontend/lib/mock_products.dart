class Product {
  final String id;
  final String title;
  final String brand;
  final double price; // Store as numeric for easier sorting/formatting
  final String imageUrl;
  final String size;
  final String condition;
  final String category; // 'Wanita', 'Pria', 'Formal', 'Daily'
  final bool isVerified;

  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.size,
    required this.condition,
    required this.category,
    this.isVerified = true,
  });

  Product copyWith({
    String? id,
    String? title,
    String? brand,
    double? price,
    String? imageUrl,
    String? size,
    String? condition,
    String? category,
    bool? isVerified,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get formattedPrice {
    // Basic Indonesian Rupiah formatting: Rp 250.000
    final buffer = StringBuffer('Rp ');
    final priceStr = price.toInt().toString();
    final len = priceStr.length;
    for (int i = 0; i < len; i++) {
      buffer.write(priceStr[i]);
      if ((len - i - 1) % 3 == 0 && i != len - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

const List<Product> mockProducts = [
  Product(
    id: 'prod_1',
    title: 'Jacket Luxury Velvet',
    brand: 'Nike',
    price: 250000,
    imageUrl: 'assets/images/PreFall.png',
    size: 'L',
    condition: 'Sangat Baik',
    category: 'Formal',
  ),
  Product(
    id: 'prod_2',
    title: 'Streetwear Puffer Jacket',
    brand: 'Eiger',
    price: 320000,
    imageUrl: 'assets/images/jacket_product.png',
    size: 'XL',
    condition: 'Sangat Baik',
    category: 'Daily',
  ),
  Product(
    id: 'prod_3',
    title: 'Retro Windbreaker Jacket',
    brand: 'Aero Street',
    price: 180000,
    imageUrl: 'assets/images/cat_daily.png',
    size: 'M',
    condition: 'Cukup Baik',
    category: 'Daily',
  ),
  Product(
    id: 'prod_4',
    title: 'Classic Wool Trench Coat',
    brand: 'Polo Ralph',
    price: 450000,
    imageUrl: 'assets/images/cat_formal.png',
    size: 'L',
    condition: 'Sangat Baik',
    category: 'Formal',
  ),
  Product(
    id: 'prod_5',
    title: 'Jacket Premium Varsity',
    brand: 'Adidas',
    price: 250000,
    imageUrl: 'assets/images/slide1.png',
    size: 'M',
    condition: 'Baik',
    category: 'Pria',
  ),
  Product(
    id: 'prod_6',
    title: 'Feminine Knitwear Cardigan',
    brand: 'Fila',
    price: 210000,
    imageUrl: 'assets/images/cat_wanita.png',
    size: 'S',
    condition: 'Sangat Baik',
    category: 'Wanita',
  ),
  Product(
    id: 'prod_7',
    title: 'Running Shoes Zoom Air',
    brand: 'Nike',
    price: 650000,
    imageUrl: 'assets/images/foryou_tall.png',
    size: '42',
    condition: 'Sangat Baik',
    category: 'Daily',
  ),
  Product(
    id: 'prod_8',
    title: 'Casual Knit Sweater',
    brand: 'New Balance',
    price: 290000,
    imageUrl: 'assets/images/banner_sweater.png',
    size: 'L',
    condition: 'Baik',
    category: 'Daily',
  ),
  Product(
    id: 'prod_9',
    title: 'California Retro Hoodie',
    brand: 'Puma',
    price: 240000,
    imageUrl: 'assets/images/Winter.png',
    size: 'M',
    condition: 'Baik',
    category: 'Pria',
  ),
  Product(
    id: 'prod_10',
    title: 'Suede Tiger Sneakers',
    brand: 'Onitsuka Tiger',
    price: 780000,
    imageUrl: 'assets/images/Spring.png',
    size: '41',
    condition: 'Sangat Baik',
    category: 'Daily',
  ),
];
