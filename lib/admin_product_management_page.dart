// lib/admin_product_management_page.dart (FINAL CORRECTED CODE)
import 'package:flutter/material.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/admin_product_detail_page.dart'; // REQUIRED

class AdminProductManagementPage extends StatefulWidget {
  const AdminProductManagementPage({super.key});

  @override
  State<AdminProductManagementPage> createState() => _AdminProductManagementPageState();
}

class _AdminProductManagementPageState extends State<AdminProductManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Product>> _allProductsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allProductsFuture = _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // FIX: Passing {'isAdminView': true} to bypass the 'approved' status filter in MongoDBService.
  Future<List<Product>> _fetchProducts() async {
    return await MongoDBService.getProducts({'isAdminView': true});
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _allProductsFuture = _fetchProducts();
    });
    await _allProductsFuture;
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

  void _navigateToDetailPage(Product product) async {
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminProductDetailPage(product: product),
      ),
    );
    if (result == true) {
      await _refreshProducts();
    }
  }

  void _quickApprove(Product product) async {
    final updatedProduct = product.copyWith(
      status: ProductStatus.approved,
      adminRemarks: 'Quickly approved by Admin.',
    );
    await MongoDBService.updateProduct(updatedProduct);
    await _refreshProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} approved!')),
      );
    }
  }

  void _quickReject(Product product) async {
    final updatedProduct = product.copyWith(
      status: ProductStatus.rejected,
      adminRemarks: 'Quickly rejected by Admin (No detailed reason provided).',
    );
    await MongoDBService.updateProduct(updatedProduct);
    await _refreshProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} rejected!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textColor,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Pending Queue'),
            Tab(text: 'Reviewed History'),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading products: ${snapshot.error}', style: bodyTextStyle.copyWith(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No products found in the system.', style: subheadingStyle));
              }

              final allProducts = snapshot.data!;
              final pendingProducts = allProducts.where((p) => p.status == ProductStatus.pending).toList();
              final reviewedProducts = allProducts.where((p) => p.status != ProductStatus.pending).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildProductList(context, pendingProducts, isPendingTab: true),
                  _buildProductList(context, reviewedProducts, isPendingTab: false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products, {required bool isPendingTab}) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            isPendingTab
                ? 'No products currently awaiting review. Great job! 🥳'
                : 'No products have been reviewed yet.',
            style: bodyTextStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductTile(
            context,
            product,
            isPending: isPendingTab,
            onTap: () => _navigateToDetailPage(product),
            onApprove: isPendingTab ? () => _quickApprove(product) : null,
            onReject: isPendingTab ? () => _quickReject(product) : null,
          );
        },
      ),
    );
  }

  Widget _buildProductTile(
      BuildContext context,
      Product product, {
        required bool isPending,
        required VoidCallback onTap,
        VoidCallback? onApprove,
        VoidCallback? onReject,
      }) {
    final statusColor = _getStatusColor(product.status);
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://via.placeholder.com/150?text=No+Image';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: inputBorderRadius),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10.0),
        onTap: onTap,
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.red)),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: subheadingStyle.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${product.status.toShortString().toUpperCase()}',
              style: bodyTextStyle.copyWith(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
            ),
            Text(
              'Submitted: ${product.createdDate.toLocal().toString().split(' ')[0]}',
              style: bodyTextStyle.copyWith(fontSize: 13),
            ),
            if (product.adminRemarks != null && !isPending)
              Text(
                'Remarks: ${product.adminRemarks}',
                style: bodyTextStyle.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: isPending
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: onReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('Approve', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ],
        )
            : IconButton(
          icon: const Icon(Icons.chevron_right, color: textColor),
          onPressed: onTap,
        ),
      ),
    );
  }
}