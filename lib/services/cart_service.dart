// lib/services/cart_service.dart

import 'package:flutter/foundation.dart';
import 'package:verdant_vault/models/cart_item.dart';

/// CartService manages cart state and notifies listeners for UI updates.
/// Use in main.dart as:
/// ChangeNotifierProvider(create: (_) => CartService())
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// Immutable view of items
  List<CartItem> get items => List.unmodifiable(_items);

  /// Subtotal (total price)
  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  /// Total number of items (sum of quantities)
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Add item to cart. If product exists, increments the quantity.
  void addItem(CartItem newItem) {
    final idx = _items.indexWhere((i) => i.productId == newItem.productId);
    if (idx >= 0) {
      // merge quantities
      final current = _items[idx];
      _items[idx] = current.copyWith(quantity: current.quantity + newItem.quantity);
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  /// Remove item by productId
  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  /// Update a product's quantity; if quantity <= 0 the item is removed.
  void updateQuantity(String productId, int quantity) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx == -1) return;
    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      final itm = _items[idx];
      _items[idx] = itm.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  /// Empties the cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Helper boolean
  bool get isEmpty => _items.isEmpty;
}
