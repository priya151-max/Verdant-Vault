// lib/admin_product_detail_page.dart
// import 'dart:io'; // ❌ REMOVED: Not needed, using Image.network
import 'package:flutter/material.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';

class AdminProductDetailPage extends StatefulWidget {
  final Product product;
  const AdminProductDetailPage({super.key, required this.product});

  @override
  State<AdminProductDetailPage> createState() => _AdminProductDetailPageState();
}

class _AdminProductDetailPageState extends State<AdminProductDetailPage> {
  String _errorMessage = '';
  bool _isLoading = false;
  late Product _currentProduct;
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    // Pre-fill remarks if they exist
    _remarksController.text = _currentProduct.adminRemarks ?? '';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _updateProductStatus(ProductStatus newStatus) async {
    // Rejection requires remarks, validate this first
    if (newStatus == ProductStatus.rejected && _remarksController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Rejection reason is required for rejection.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final updatedProduct = _currentProduct.copyWith(
        status: newStatus,
        adminRemarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
      );

      await MongoDBService.updateProduct(updatedProduct);

      if (mounted) {
        setState(() {
          _currentProduct = updatedProduct; // Update local state
        });
        // Show success and pop after a short delay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product status updated to ${newStatus.toShortString().toUpperCase()}')),
        );
        Navigator.of(context).pop(true); // Indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update status: $e';
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
    // Ensure product has at least one image URL before attempting to display it
    final imageUrl = _currentProduct.imageUrls.isNotEmpty ? _currentProduct.imageUrls.first : 'https://via.placeholder.com/150?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Product', style: appTitleStyle.copyWith(fontSize: 24)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(_currentProduct.name, style: headingStyle),
                      ),
                      const Divider(height: 30),

                      // Image Display (from Network)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: Image.network(
                              imageUrl, // 👈 Uses the remote URL
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.red)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Badge
                      Center(
                        child: Chip(
                          label: Text(
                            'STATUS: ${_currentProduct.status.toShortString().toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(_currentProduct.status),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details Rows
                      _buildDetailRow(Icons.euro, 'Price', '€${_currentProduct.price.toStringAsFixed(2)}'),
                      _buildDetailRow(Icons.category, 'Category', _currentProduct.category),
                      _buildDetailRow(Icons.inventory, 'Stock', _currentProduct.stockCount.toString()),
                      _buildDetailRow(Icons.store, 'Seller ID', _currentProduct.sellerId),
                      _buildDetailRow(Icons.label, 'Tags', _currentProduct.sustainabilityTags.join(', ')),

                      const SizedBox(height: 16),
                      Text('Description:', style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
                      Text(_currentProduct.description, style: bodyTextStyle),

                      const SizedBox(height: 30),

                      // Admin Remarks Section
                      Text('Admin Review/Remarks', style: subheadingStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Reason for rejection/approval notes',
                          border: const OutlineInputBorder(borderRadius: inputBorderRadius),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: primaryColor))
                      else
                        Row(
                          children: [
                            // Reject Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentProduct.status != ProductStatus.rejected
                                    ? () => _updateProductStatus(ProductStatus.rejected)
                                    : null, // Only enable if not already rejected
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('REJECT', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Approve Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentProduct.status != ProductStatus.approved
                                    ? () => _updateProductStatus(ProductStatus.approved)
                                    : null, // Only enable if not already approved
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
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

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.approved:
        return Colors.green.shade700;
      case ProductStatus.pending:
        return Colors.orange.shade700;
      case ProductStatus.rejected:
        return Colors.red.shade700;
      case ProductStatus.deactivated:
        return Colors.blueGrey.shade700;
      default:
        return textColor;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Text('$label: ', style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: bodyTextStyle)),
        ],
      ),
    );
  }
}