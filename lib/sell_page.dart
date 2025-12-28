// lib/sell_page.dart (FINAL CORRECTED VERSION - WITH OPTIONAL IMAGE URL INPUT)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/models/seller.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/seller_registration_page.dart';
import 'package:uuid/uuid.dart'; // REQUIRED for generating Product ID

// The SellPage is where a registered seller lists a new product.
class SellPage extends StatefulWidget {
  final String userId;
  const SellPage({super.key, required this.userId});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _tagsController = TextEditingController();
  // NEW: Controller for optional image URL
  final _imageUrlController = TextEditingController();

  String? _selectedCategory;
  List<String> _imagePaths = []; // Stores local file paths for file upload option
  final ImagePicker _picker = ImagePicker();

  String _errorMessage = '';
  bool _isLoading = false;

  Seller? _seller;
  bool _isSellerRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _checkSellerStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final seller = await MongoDBService.getSeller(widget.userId);
      setState(() {
        _seller = seller;
        _isSellerRegistered = seller != null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking seller status: ${e.toString()}';
        _isSellerRegistered = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Opens the image picker to select multiple images (for file upload option).
  Future<void> _pickImage() async {
    // Only allow file upload if no URL has been manually entered
    if (_imageUrlController.text.isNotEmpty) {
      setState(() => _errorMessage = 'Clear the Image URL field to use file upload.');
      return;
    }

    if (_imagePaths.length >= 5) {
      setState(() => _errorMessage = 'Maximum of 5 images allowed.');
      return;
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 800,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 5 - _imagePaths.length;
        _imagePaths.addAll(pickedFiles.take(remainingSlots).map((f) => f.path));
        _errorMessage = '';
      });
    }
  }

  /// Removes an image path from the list.
  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  /// Handles the core logic: Form validation, Image upload, and DB insertion.
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || _seller == null) return;

    final urlInput = _imageUrlController.text.trim();

    // Check if either local files or a URL has been provided
    if (_imagePaths.isEmpty && urlInput.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one image or provide an Image URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<String> finalImageUrls = [];

      if (urlInput.isNotEmpty) {
        // 1. USE URL INPUT (Prioritized and simpler)
        finalImageUrls = [urlInput];
        // NOTE: In a real app, you'd want to validate this URL is reachable
      } else {
        // 2. UPLOAD LOCAL IMAGES
        finalImageUrls = await MongoDBService.uploadImages(_imagePaths);
        if (finalImageUrls.isEmpty) {
          throw Exception('Image upload failed: The backend returned an empty URL list.');
        }
      }

      // 3. CREATE PRODUCT OBJECT
      const Uuid uuid = Uuid();
      final newProduct = Product(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        sellerId: widget.userId,
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        stockCount: int.parse(_stockController.text.trim()),
        sustainabilityTags: _tagsController.text.trim().split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        imageUrls: finalImageUrls, // Use the final URL(s)
        status: ProductStatus.pending,
        createdDate: DateTime.now(),
      );

      // 4. SAVE PRODUCT DETAILS TO DATABASE
      await MongoDBService.createProduct(newProduct);

      // 5. SUCCESS: Clear form and notify user
      _formKey.currentState!.reset();
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _stockController.clear();
      _tagsController.clear();
      _imageUrlController.clear(); // Clear URL input
      setState(() {
        _selectedCategory = null;
        _imagePaths.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product submitted for review successfully!'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit product or image(s). Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (!_isSellerRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SellerRegistrationPage(
              userId: widget.userId,
              onRegistrationComplete: _checkSellerStatus,
            ),
          ),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('List a New Product', style: appTitleStyle.copyWith(fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... (Existing text fields: Name, Category, Price, Stock, Description, Tags) ...
                  TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag, color: primaryColor.withOpacity(0.7))), validator: (value) => value!.isEmpty ? 'Please enter a product name' : null),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category, color: primaryColor.withOpacity(0.7)), border: const OutlineInputBorder(borderRadius: inputBorderRadius), fillColor: Colors.white, filled: true),
                    items: ecoCategories.skip(1).map((category) { return DropdownMenuItem(value: category, child: Text(category)); }).toList(),
                    onChanged: (String? newValue) { setState(() { _selectedCategory = newValue; }); },
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price (€)', prefixIcon: Icon(Icons.euro, color: primaryColor.withOpacity(0.7))), validator: (value) { if (value!.isEmpty) return 'Enter price'; if (double.tryParse(value) == null) return 'Invalid number'; return null; })), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _stockController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock Count', prefixIcon: Icon(Icons.inventory, color: primaryColor.withOpacity(0.7))), validator: (value) { if (value!.isEmpty) return 'Enter stock'; if (int.tryParse(value) == null) return 'Invalid integer'; return null; })), ],),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descriptionController, maxLines: 4, decoration: InputDecoration(labelText: 'Product Description', alignLabelWithHint: true, prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 50.0), child: Icon(Icons.description, color: primaryColor.withOpacity(0.7)))), validator: (value) => value!.isEmpty ? 'Please describe your product' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _tagsController, decoration: InputDecoration(labelText: 'Sustainability Tags (e.g., Organic, Fair Trade, Recycled)', hintText: 'Separate tags with a comma', prefixIcon: Icon(Icons.label, color: primaryColor.withOpacity(0.7)))),
                  const SizedBox(height: 24),

                  // --- NEW: Image URL Input ---
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Optional: Direct Image URL',
                      hintText: 'e.g., https://mysite.com/product.jpg',
                      prefixIcon: Icon(Icons.link, color: accentColor),
                    ),
                    onChanged: (value) {
                      // Clear local file paths if user starts typing a URL
                      if (value.isNotEmpty && _imagePaths.isNotEmpty) {
                        setState(() {
                          _imagePaths.clear();
                          _errorMessage = 'Local files cleared. Using URL input.';
                        });
                      } else if (value.isEmpty) {
                        setState(() {
                          _errorMessage = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Image Upload Section (Hidden if URL is present) ---
                  if (_imageUrlController.text.isEmpty) ...[
                    Text('OR Upload Images (${_imagePaths.length}/5 selected)', style: subheadingStyle),
                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.cloud_upload, color: primaryColor),
                      label: const Text('Add Images (Max 5)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Preview Grid
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(_imagePaths[index]),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],


                  // Submit Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryColor))
                      : ElevatedButton(
                    onPressed: _submitProduct,
                    child: const Text('Submit for Review'),
                  ),

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}