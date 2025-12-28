import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/services/cart_service.dart';
import 'package:verdant_vault/models/cart_item.dart';
import 'package:verdant_vault/product_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {
  String _selectedCategory = ecoCategories.first; // Default category: "All"

  // 🌐 External API for fetching products
  static const String _externalApiUrl =
      "https://varying-plum-mcpw3uchgb.edgeone.app/api/products";

  // Fetch approved products from external API with MongoDB fallback
  Future<List<Product>> _fetchApprovedProducts() async {
    List<Product> approvedProducts = [];

    try {
      // --- 1️⃣ Attempt External API Fetch ---
      final response = await http.get(Uri.parse(_externalApiUrl));

      if (response.statusCode == 200) {
        final body = response.body;

        // Handle possible wrapped API responses (in case it’s a map)
        final data = json.decode(body);
        final List<dynamic> jsonList =
        data is List ? data : (data['products'] ?? []);

        approvedProducts =
            jsonList.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('External API fetch failed (Status: ${response.statusCode})');
      }
    } catch (e) {
      // --- 2️⃣ Fallback: Fetch from MongoDB ---
      debugPrint('⚠️ External API failed: $e. Falling back to MongoDBService...');
      final query = {'status': ProductStatus.approved};
      approvedProducts = await MongoDBService.getProducts(query);
    }

    // --- 3️⃣ Filter by selected category (client-side) ---
    if (_selectedCategory != 'All') {
      approvedProducts = approvedProducts
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    return approvedProducts;
  }

  void _onCategorySelected(String? newCategory) {
    if (newCategory != null && newCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = newCategory;
      });
    }
  }

  // 🧱 Product Card Widget
  Widget _buildProductCard(Product product) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : 'https://via.placeholder.com/150?text=No+Image';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: cardBorderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🖼️ Image Section
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 50, color: accentColor),
                    ),
                  ),
                ),
              ),
            ),

            // 🏷️ Product Details Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: subheadingStyle.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${product.price.toStringAsFixed(2)}',
                    style: bodyTextStyle.copyWith(
                        fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: product.stockCount > 0
                          ? () {
                        final newItem = CartItem(
                          productId: product.id,
                          name: product.name,
                          price: product.price,
                          imageUrl: imageUrl,
                          quantity: 1,
                        );
                        cartService.addItem(newItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            Text('${product.name} added to cart!'),
                            duration:
                            const Duration(milliseconds: 1000),
                            backgroundColor: primaryColor,
                          ),
                        );
                      }
                          : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(
                        product.stockCount > 0
                            ? 'Add to Cart'
                            : 'Out of Stock',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.stockCount > 0
                            ? secondaryColor
                            : Colors.grey.shade400,
                        foregroundColor: product.stockCount > 0
                            ? primaryColor
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
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

  // 🧩 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Eco-Friendly',
            style: appTitleStyle.copyWith(fontSize: 24)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: Column(
          children: [
            // 🔽 Category Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Category',
                  prefixIcon: Icon(Icons.filter_list,
                      color: primaryColor.withOpacity(0.7)),
                  border: const OutlineInputBorder(
                      borderRadius: inputBorderRadius),
                  fillColor: Colors.white,
                  filled: true,
                ),
                value: _selectedCategory,
                items: ecoCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _onCategorySelected,
              ),
            ),

            // 🛍️ Product Grid
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _fetchApprovedProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                        CircularProgressIndicator(color: primaryColor));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading products: ${snapshot.error}',
                        style:
                        bodyTextStyle.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No approved products found.',
                        style: subheadingStyle,
                      ),
                    );
                  }

                  final products = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(products[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
