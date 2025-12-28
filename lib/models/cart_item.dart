// lib/models/cart_item.dart

/// Represents a single item inside the shopping cart.
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  /// Create a copy with modified fields (used for updates).
  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Compute total price for this item
  double get total => price * quantity;

  /// Convert to a Map for saving in database or API
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  /// Construct from a Map (e.g., from MongoDB or local JSON)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl']?.toString() ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
    );
  }

  /// Convert this object to a readable string for debugging/logging
  @override
  String toString() =>
      'CartItem(productId: $productId, name: $name, price: $price, quantity: $quantity)';
}
