// lib/seller_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/models/seller.dart';
import 'package:verdant_vault/edit_product_page.dart';
import 'package:verdant_vault/sell_page.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/login_page.dart';

// Assuming ProductStatus.toShortString() is correctly defined in lib/models/product.dart
// and ProductStatus is an imported enum.

typedef RefreshCallback = Future<void> Function();

class SellerDashboardPage extends StatefulWidget {
  final String userId;
  const SellerDashboardPage({super.key, required this.userId});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  Seller? _seller;
  List<Product> _products = [];
  String _errorMessage = '';

  // New State Variables for Dashboard Stats
  double _totalSales = 0.0;
  int _ecoPoints = 50; // Initial base eco-points as requested

  @override
  void initState() {
    super.initState();
    _animationController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadSellerData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _totalSales = 0.0;
      _ecoPoints = 50; // Reset to base
    });

    try {
      final seller = await MongoDBService.getSeller(widget.userId);

      if (seller == null) {
        throw Exception('Seller profile not found. Please register.');
      }

      // 1. Fetch Products
      final products = await MongoDBService.getProducts({'sellerId': widget.userId});

      // 2. Fetch Sales Data (Simulated Purchase History to calculate points and sales)
      final salesData = await MongoDBService.getSellerSalesHistory(widget.userId);

      // 3. Calculate Total Sales and Eco-Points
      double salesTotal = 0.0;
      int pointsEarned = 0;

      // Calculate sales total and points based on purchase data
      for (var sale in salesData) {
        // Assuming 'totalAmount' is the field for the value of the sale
        salesTotal += (sale['totalAmount'] as num? ?? 0.0).toDouble();

        // Logic: Add 10 Eco-Points for *each* transaction (or purchase), as requested.
        pointsEarned += 10;
      }

      // Update state
      setState(() {
        _seller = seller;
        _products = products;
        _totalSales = salesTotal;
        _ecoPoints = 50 + pointsEarned; // Base 50 + earned points
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditProduct(Product product) async {
    // Navigate to the edit page and wait for the result (true if updated/deleted)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProductPage(product: product)),
    );

    // If a product was modified or deleted, refresh the list
    if (result == true) {
      _loadSellerData();
    }
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    // 🎯 Ensures stats don't take up too much vertical space and is centered
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          value,
          style: headingStyle.copyWith(color: color, fontSize: 28),
          overflow: TextOverflow.ellipsis,
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: bodyTextStyle.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow two lines for labels like "Approved Count"
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper to build the main stats card
  Widget _buildStatsSection(BuildContext context) {
    final approvedCount = _products.where((p) => p.status == ProductStatus.approved).length;
    final pendingCount = _products.where((p) => p.status == ProductStatus.pending).length;

    // Total sales and Eco-Points are now state variables
    final totalSalesFormatted = _totalSales.toStringAsFixed(2);
    final ecoPointsFormatted = _ecoPoints.toString();

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // 🎯 FIX: Wrap all _buildStatColumn widgets in Expanded to prevent the RenderFlex overflow.
            children: [
              Expanded(child: _buildStatColumn('Approved', approvedCount.toString(), primaryColor)),
              const VerticalDivider(width: 1, color: Colors.grey),
              Expanded(child: _buildStatColumn('Pending', pendingCount.toString(), Colors.orange)),
              const VerticalDivider(width: 1, color: Colors.grey),
              Expanded(child: _buildStatColumn('Sales (€)', totalSalesFormatted, secondaryColor)),
              const VerticalDivider(width: 1, color: Colors.grey),
              // Use state variable for Eco-Points
              Expanded(child: _buildStatColumn('Eco-Pts', ecoPointsFormatted, Colors.blueAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: product.imageUrls.isNotEmpty
            ? SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              product.imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
        )
            : const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
        title: Text(product.name,
            style: subheadingStyle.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: €${product.price.toStringAsFixed(2)}',
                style: bodyTextStyle.copyWith(color: primaryColor)),
            Text('Stock: ${product.stockCount}',
                style: bodyTextStyle.copyWith(fontSize: 14)),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.status == ProductStatus.approved
                    ? Colors.green.shade100
                    : product.status == ProductStatus.pending
                    ? Colors.orange.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(product.status.toShortString().toUpperCase(),
                  style: bodyTextStyle.copyWith(
                      color: product.status == ProductStatus.approved
                          ? Colors.green.shade800
                          : product.status == ProductStatus.pending
                          ? Colors.orange.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            // Show rejection reason only if rejected
            if (product.status == ProductStatus.rejected && product.adminRemarks != null)
              Tooltip(
                message: 'Reason: ${product.adminRemarks}',
                child: const Icon(Icons.info_outline, size: 16, color: Colors.red),
              ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvedCount =
        _products.where((p) => p.status == ProductStatus.approved).length;
    final pendingCount =
        _products.where((p) => p.status == ProductStatus.pending).length;
    // Calculate products that are rejected or deactivated
    final notListedCount = _products.where((p) =>
    p.status == ProductStatus.rejected ||
        p.status == ProductStatus.deactivated
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_seller?.businessName ?? 'Seller Dashboard', style: appTitleStyle),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: primaryColor),
            tooltip: 'List New Product',
            onPressed: () async {
              // Navigate to SellPage and wait for refresh if product is added
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SellPage(userId: widget.userId)),
              );
              if (result == true) {
                _loadSellerData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Log Out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: RefreshIndicator(
          onRefresh: _loadSellerData,
          color: primaryColor,
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(
                    child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(color: primaryColor)))
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(context),
                    const SizedBox(height: 24),

                    // Product Listings Header
                    Text('My Product Listings (${_products.length})',
                        style: subheadingStyle.copyWith(color: primaryColor)),
                    Text(
                        '$approvedCount Approved, $pendingCount Pending Review, '
                            '$notListedCount Rejected/Deactivated',
                        style: bodyTextStyle.copyWith(fontSize: 14)),
                    const SizedBox(height: 16),
                    if (_products.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text('You have no products listed yet.',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic))))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _buildProductTile(
                              product, () => _navigateToEditProduct(product));
                        },
                      ),
                    const SizedBox(height: 40),
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