// lib/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/services/cart_service.dart' as cart_service; // 🎯 FIX 1: Import with alias
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/cart_item.dart'; // Ensure CartItem.toMap() is available

class CheckoutPage extends StatefulWidget {
  final String userId;
  const CheckoutPage({super.key, required this.userId});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final double _ecoPointValue = 0.01; // €0.01 discount per Eco-Point
  int _userEcoPoints = 0;
  bool _useEcoPoints = true;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // NOTE: MongoDBService.getUser is assumed to return a Map with 'ecoPoints' and 'address'
      final user = await MongoDBService.getUser(widget.userId);
      if (user != null) {
        setState(() {
          _userEcoPoints = user['ecoPoints'] as int? ?? 0;
          _addressController.text = user['address'] as String? ?? '123 Green Street, Earth City';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User data not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  // 🎯 FIX 2: Use aliased CartService type
  Future<void> _processPayment(cart_service.CartService cartService) async {
    if (_addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a delivery address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final subtotal = cartService.subtotal;
    final maxDiscount = _userEcoPoints * _ecoPointValue;
    // Discount is the lesser of max points value or the subtotal amount
    final applicableDiscount = _useEcoPoints ? subtotal.clamp(0.0, maxDiscount) : 0.0;
    final finalTotal = subtotal - applicableDiscount;

    // Calculate points used and remaining points
    final pointsUsed = (_useEcoPoints ? (applicableDiscount / _ecoPointValue).round() : 0);
    final newEcoPoints = _userEcoPoints - pointsUsed;

    try {
      // 1. Create the Order
      // CartItem.toMap() is assumed to exist in lib/models/cart_item.dart
      final orderData = {
        'userId': widget.userId,
        'items': cartService.items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'discount': applicableDiscount,
        'ecoPointsUsed': pointsUsed,
        'totalPaid': finalTotal,
        'deliveryAddress': _addressController.text.trim(),
        'paymentMethod': 'Eco-Pay Simulation', // Placeholder
      };
      await MongoDBService.createOrder(orderData);

      // 2. Update User Eco-Points
      // MongoDBService.updateEcoPoints is assumed to update the user's point total
      await MongoDBService.updateEcoPoints(widget.userId, newEcoPoints);

      // 3. Clear Cart
      cartService.clearCart();

      // 4. Success Feedback & Notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Successful! Confirmation sent via email/notification.')),
        );
        print('SUCCESS: Order for €${finalTotal.toStringAsFixed(2)} placed. New Eco-Points: $newEcoPoints');

        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX 3: Use aliased CartService type
    final cartService = Provider.of<cart_service.CartService>(context);
    final subtotal = cartService.subtotal;
    final maxDiscount = _userEcoPoints * _ecoPointValue;
    final applicableDiscount = _useEcoPoints ? subtotal.clamp(0.0, maxDiscount) : 0.0;
    final finalTotal = subtotal - applicableDiscount;

    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: const Center(child: CircularProgressIndicator(color: primaryColor))
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Payment'), backgroundColor: primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Address', style: headingStyle),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Full Delivery Address', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const Divider(height: 32),

            // 🎯 FIX 4: Inserted Cart Items list section (potential fix for line 99 type error)
            Text('Items in Order', style: headingStyle),
            const SizedBox(height: 16),
            ...cartService.items.map((item) => _buildCartItemRow(item)).toList(),
            const Divider(height: 32),

            Text('Eco-Points Discount', style: headingStyle),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Eco-Points:', style: bodyTextStyle),
                        Text('$_userEcoPoints Pts', style: ecoCreditTextStyle),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Max Discount (1 Pt = €0.01):', style: bodyTextStyle),
                        Text('€${maxDiscount.toStringAsFixed(2)}', style: ecoCreditTextStyle),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Apply Eco-Points Discount', style: bodyTextStyle),
                      value: _useEcoPoints,
                      onChanged: (bool value) {
                        setState(() { _useEcoPoints = value; });
                      },
                      activeColor: primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),

            Text('Order Summary', style: headingStyle),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', subtotal),
            _buildSummaryRow('Discount Applied', -applicableDiscount, color: Colors.red),
            const Divider(),
            _buildSummaryRow('Total Due', finalTotal, style: headingStyle.copyWith(color: primaryColor)),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _processPayment(cartService),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text('Pay €${finalTotal.toStringAsFixed(2)}', style: buttonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 FIX 5: Helper method for displaying a single cart item row
  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.name} (x${item.quantity})',
              style: bodyTextStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '€${(item.price * item.quantity).toStringAsFixed(2)}',
            style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color color = textColor, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? bodyTextStyle.copyWith(color: color)),
          Text(value.toStringAsFixed(2), style: style ?? bodyTextStyle.copyWith(color: color)),
        ],
      ),
    );
  }
}