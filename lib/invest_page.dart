// lib/invest_page.dart
import 'package:flutter/material.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/seller.dart';
import 'package:verdant_vault/services/mongodb_service.dart'; // NEW: Import MongoDB Service

class InvestPage extends StatelessWidget {
  const InvestPage({super.key});

  // Helper method for the Insight Cards
  Widget _buildInsightCards() {
    return Row(
      // FIX: Use Expanded on children to prevent horizontal overflow (already done)
      children: [
        // Card 1 - Wrapped in Expanded
        Expanded(
          child: _buildInsightCard(
            title: 'Verified Sellers',
            value: '520+',
            icon: Icons.store_mall_directory,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        // Card 2 - Wrapped in Expanded
        Expanded(
          child: _buildInsightCard(
            title: 'Total Impact',
            value: '4.5M €', // Using Euro symbol as a common currency
            icon: Icons.eco,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  // Helper method for a single Insight Card
  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(title, style: bodyTextStyle.copyWith(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: headingStyle.copyWith(color: textColor, fontSize: 28),
              // ADDED: Prevent overflow on large numbers
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for a Seller Tile
  Widget _buildSellerTile(BuildContext context, Seller seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: inputBorderRadius),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: CircleAvatar(
          backgroundColor: secondaryColor,
          child: Text(seller.businessName.substring(0, 1).toUpperCase(),
              style: subheadingStyle.copyWith(color: primaryColor)),
        ),
        // 💡 FIX: Wrap content in Expanded inside the ListTile to give it the full available width
        // and safely truncate text when the trailing widget is present.
        title: Text(
          seller.businessName,
          style: subheadingStyle.copyWith(fontSize: 18),
          overflow: TextOverflow.ellipsis, // Ensure overflow safety
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ensure the description is also safe from overflow
            Text(
                seller.businessDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyTextStyle.copyWith(fontSize: 14)
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('Credit Score: ${seller.creditScore.toStringAsFixed(1)}',
                    style: ecoCreditTextStyle.copyWith(fontSize: 14)),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Mock investment action
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Simulating investment in ${seller.businessName}')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // Optional: Reduce min width to allow more space for title/subtitle
            minimumSize: const Size(80, 36),
          ),
          child: const Text('Invest'),
        ),
      ),
    );
  }

  // Method to fetch sellers visible to investors
  Future<List<Seller>> _fetchVisibleSellers() async {
    return await MongoDBService.getVisibleSellers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invest in Sustainability', style: appTitleStyle.copyWith(fontSize: 24)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: FutureBuilder<List<Seller>>(
          future: _fetchVisibleSellers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryColor));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading sellers: ${snapshot.error}', style: bodyTextStyle.copyWith(color: Colors.red)));
            }

            final visibleSellers = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Green Investment Opportunities', style: headingStyle),
                  Text('Fund vetted sellers and track your positive environmental impact.',
                      style: bodyTextStyle),
                  const SizedBox(height: 24),

                  // --- Quick Insight Cards ---
                  _buildInsightCards(),
                  const SizedBox(height: 24),

                  // --- Top Performing Sellers Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Performing Sellers', style: subheadingStyle),
                      TextButton(
                        onPressed: () {
                          // Mock navigation to full list
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Viewing All Sellers...')),
                          );
                        },
                        child: const Text('View All', style: TextStyle(color: primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Seller List ---
                  if (visibleSellers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text('No sellers currently open for investment.', style: bodyTextStyle.copyWith(fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                  // Use ListView.builder if the list is potentially very long,
                  // but since it's inside a SingleChildScrollView, a simple map is fine.
                    ...visibleSellers.map((seller) => _buildSellerTile(context, seller)).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}