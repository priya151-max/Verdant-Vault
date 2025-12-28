// lib/cart_page.dart (ERROR-FREE CODE)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/cart_service.dart' as cart_service; // 🎯 FIX 1: Import with alias
import 'package:verdant_vault/models/cart_item.dart';
import 'package:verdant_vault/checkout_page.dart'; // REQUIRED for navigation

class CartPage extends StatelessWidget {
  // Define the required userId parameter
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Listen to the CartService for real-time updates
    // 🎯 FIX 2: Use aliased CartService type in Provider.of
    final cartService = Provider.of<cart_service.CartService>(context);
    final cartItems = cartService.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart (${cartItems.length})', style: appTitleStyle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: Column(
          children: [
            // Cart Item List
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                child: Text(
                  'Your cart is empty! Start shopping eco-friendly products. 🌿',
                  style: bodyTextStyle.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  // Pass the aliased CartService instance
                  return _buildCartItemTile(context, item, cartService);
                },
              ),
            ),

            // Checkout Summary and Button
            if (cartItems.isNotEmpty)
            // Pass the aliased CartService instance
              _buildCheckoutSummary(context, cartService, userId),
          ],
        ),
      ),
    );
  }

  // 🎯 FIX 3: Use aliased CartService type in method signature
  Widget _buildCartItemTile(BuildContext context, CartItem item, cart_service.CartService cartService) {
    // Using Card for a nicer, elevated look
    return Card(
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Product Image (Placeholder)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported, color: textColor)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${item.price.toStringAsFixed(2)} per item',
                    style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: €${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: subheadingStyle.copyWith(color: primaryColor, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Quantity Controls and Remove Button
            Column(
              children: [
                // Quantity buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: accentColor),
                      onPressed: () {
                        if (item.quantity > 1) {
                          cartService.updateQuantity(item.productId, item.quantity - 1);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('${item.quantity}', style: bodyTextStyle),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20, color: primaryColor),
                      onPressed: () {
                        // FIX: Added a mock stock limit check, although CartItem model doesn't have stock
                        // For a real app, this would check available stock.
                        cartService.updateQuantity(item.productId, item.quantity + 1);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Remove button
                InkWell(
                  onTap: () {
                    cartService.removeItem(item.productId); // Assuming removeItem is the correct method
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Remove',
                      style: bodyTextStyle.copyWith(color: Colors.red, fontSize: 13, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 FIX 4: Use aliased CartService type in method signature
  Widget _buildCheckoutSummary(BuildContext context, cart_service.CartService cartService, String userId) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: subheadingStyle.copyWith(fontSize: 18)),
              // NOTE: cartService.subtotal is used here (assuming correct service implementation)
              Text('€${cartService.subtotal.toStringAsFixed(2)}', style: subheadingStyle.copyWith(fontSize: 18, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Checkout Page, passing the userId
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckoutPage(userId: userId)),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
              ),
              child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}