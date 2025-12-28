// lib/seller_registration_page.dart (CORRECTED)

import 'package:flutter/material.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/seller.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/seller_dashboard_page.dart';

class SellerRegistrationPage extends StatefulWidget {
  final String userId;
  final VoidCallback? onRegistrationComplete; // Callback to refresh calling page
  const SellerRegistrationPage({super.key, required this.userId, this.onRegistrationComplete});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isVisibleToInvestors = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Register new seller
  Future<void> _registerSeller() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if seller already exists (redundant if called correctly, but safe)
      final existingSeller = await MongoDBService.getSeller(widget.userId);
      if (existingSeller != null) {
        throw Exception('Seller profile already exists for this user.');
      }

      // Create new Seller model
      final newSeller = Seller(
        userId: widget.userId,
        businessName: _businessNameController.text.trim(),
        address: _addressController.text.trim(),
        businessDescription: _descriptionController.text.trim(),
        isVisibleToInvestors: _isVisibleToInvestors,
        creditScore: 5.0, // Initialize with a high score
        productIds: [],
      );

      // Create seller profile in MongoDB
      await MongoDBService.createSeller(newSeller);

      if (mounted) {
        // Run callback if provided
        widget.onRegistrationComplete?.call();

        // Navigate to the Seller Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller registration complete!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SellerDashboardPage(userId: widget.userId)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to register seller: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Registration', style: appTitleStyle.copyWith(fontSize: 24)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Business Profile', style: headingStyle),
                      const SizedBox(height: 20),
                      // Business Name
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.store, color: primaryColor.withOpacity(0.7)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter business name' : null,
                      ),
                      const SizedBox(height: 16),
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Business Address',
                          prefixIcon: Icon(Icons.location_on, color: primaryColor.withOpacity(0.7)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter business address' : null,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Business Description / Eco Mission',
                          prefixIcon: Icon(Icons.eco, color: primaryColor.withOpacity(0.7)),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter business description' : null,
                      ),
                      const SizedBox(height: 24),

                      // Investor Visibility Toggle
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Visible to Investors (Fundraising)',
                              style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: _isVisibleToInvestors,
                            onChanged: (value) => setState(() {
                              _isVisibleToInvestors = value;
                            }),
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton.icon(
                        onPressed: _registerSeller,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete Registration'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}