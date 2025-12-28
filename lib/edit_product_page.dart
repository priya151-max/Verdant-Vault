// lib/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart'; // NEW: Import MongoDB Service

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _tagsController;
  late final TextEditingController _imageUrlController; // Mock single image URL field

  String _errorMessage = '';
  bool _isLoading = false;
  String? _selectedCategory; // Actual field for dropdown

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _stockController = TextEditingController(text: widget.product.stockCount.toString());
    _tagsController = TextEditingController(text: widget.product.sustainabilityTags.join(', '));
    // Use the first image URL for mock editing
    _imageUrlController = TextEditingController(text: widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '');

    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> updateProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        stockCount: int.parse(_stockController.text),
        sustainabilityTags: _tagsController.text.split(',').map((s) => s.trim()).toList(),
        // Mock image URL update
        imageUrls: [_imageUrlController.text.trim()],
      );

      // 🎯 MongoDB Service Call
      await MongoDBService.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.of(context).pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update product: ${e.toString()}';
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

  Future<void> deleteProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 🎯 MongoDB Service Call
      await MongoDBService.deleteProduct(widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        Navigator.of(context).pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete product: ${e.toString()}';
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
        title: Text('Edit Product: ${widget.product.name}', style: appTitleStyle.copyWith(fontSize: 24)),
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
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('General Information', style: headingStyle),
                    const SizedBox(height: 20),
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.shopping_bag, color: primaryColor.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category, color: primaryColor.withOpacity(0.7)),
                        border: const OutlineInputBorder(borderRadius: inputBorderRadius),
                      ),
                      value: _selectedCategory,
                      hint: const Text('Select Category'),
                      items: ecoCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != 'All') {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (€)',
                        prefixIcon: Icon(Icons.euro, color: primaryColor.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stock Count
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Count',
                        prefixIcon: Icon(Icons.inventory, color: primaryColor.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description, color: primaryColor.withOpacity(0.7)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Sustainability Tags (comma separated)',
                        prefixIcon: Icon(Icons.label, color: primaryColor.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image URL (Mocked field for remote image editing)
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL (First Image)',
                        prefixIcon: Icon(Icons.image, color: primaryColor.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryColor))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: updateProduct,
                          child: const Text('Update Product'),
                        ),
                        ElevatedButton(
                          onPressed: deleteProduct,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete Product'),
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
    );
  }
}