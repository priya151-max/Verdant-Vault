// lib/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/cart_item.dart';
// 🎯 This import MUST be correct for CartService to be recognized as a type
import 'package:verdant_vault/services/cart_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      if (_quantity < widget.product.stockCount) {
        _quantity++;
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  void _addToCart() {
    if (_quantity > 0) {
      // FIX: The usage of Provider.of<CartService> is correct, assuming the import
      // at the top is valid and CartService is defined in lib/services/cart_service.dart
      final cartService = Provider.of<CartService>(context, listen: false);
      final newItem = CartItem(
        productId: widget.product.id,
        name: widget.product.name,
        price: widget.product.price,
        imageUrl: widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '',
        quantity: _quantity,
      );
      cartService.addItem(newItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity x ${widget.product.name} added to cart!'),
          backgroundColor: primaryColor,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://via.placeholder.com/600?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, style: appTitleStyle.copyWith(fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image (Full Width)
            Image.network(
              imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const SizedBox(height: 300, child: Center(child: Icon(Icons.broken_image, size: 80, color: accentColor))),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: appTitleStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${product.price.toStringAsFixed(2)}',
                    style: subheadingStyle.copyWith(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Tags and Stock Info
                  Wrap(
                    spacing: 8.0,
                    children: [
                      Chip(
                        label: Text(product.category),
                        backgroundColor: secondaryColor,
                      ),
                      ...product.sustainabilityTags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.lightGreen.shade100,
                      )).toList(),
                      Chip(
                        label: Text('Stock: ${product.stockCount}', style: TextStyle(color: product.stockCount > 5 ? primaryColor : Colors.red)),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Description
                  Text('Description', style: subheadingStyle),
                  const SizedBox(height: 8),
                  Text(product.description, style: bodyTextStyle.copyWith(fontSize: 16)),
                  const Divider(height: 32),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity', style: subheadingStyle),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _decrementQuantity,
                            icon: const Icon(Icons.remove_circle_outline, color: primaryColor),
                            tooltip: 'Decrease quantity',
                          ),
                          Text('$_quantity', style: subheadingStyle.copyWith(fontSize: 20)),
                          IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add_circle_outline, color: primaryColor),
                            tooltip: 'Increase quantity',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: product.stockCount > 0 ? _addToCart : null,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(product.stockCount > 0 ? 'Add to Cart' : 'Out of Stock'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}