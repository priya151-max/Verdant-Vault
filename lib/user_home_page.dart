// lib/user_home_page.dart (FINAL COMPLETE CODE - WITH ENHANCED ANIMATION)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/buy_page.dart'; // Placeholder dependency
import 'package:verdant_vault/invest_page.dart'; // Placeholder dependency
import 'package:verdant_vault/cart_page.dart'; // Placeholder dependency
import 'package:verdant_vault/report_product_page.dart'; // NEW: Import Report Page

// Use 'show' to import only the necessary class and avoid conflicts
import 'package:verdant_vault/sell_page.dart' show SellPage; // Placeholder dependency
import 'package:verdant_vault/seller_dashboard_page.dart' show SellerDashboardPage; // Placeholder dependency

import 'package:verdant_vault/seller_registration_page.dart'; // Placeholder dependency
import 'package:verdant_vault/login_page.dart'; // Placeholder dependency
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/models/seller.dart'; // Placeholder dependency
import 'package:verdant_vault/models/product.dart'; // Placeholder dependency
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/services/cart_service.dart'; // Placeholder dependency

// --- PLACEHOLDER WIDGETS ---
class ChatPage extends StatelessWidget {
  final String sellerId;
  const ChatPage({super.key, required this.sellerId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with Seller ID: ${sellerId.substring(0, 8)}...')),
      body: Center(child: Text('Chat interface with seller $sellerId', style: bodyTextStyle)),
    );
  }
}

// --- HISTORY TAB WIDGETS ---

class PurchaseHistoryTab extends StatelessWidget {
  final String userId;
  const PurchaseHistoryTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDBService.getPurchaseHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Center(child: Text('No purchase history found. Start shopping!', style: bodyTextStyle));
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final order = history[index];
            return ListTile(
              title: Text('Order ID: ${order['orderId'].substring(0, 8)}...'),
              subtitle: Text('${(order['items'] as List).length} items | Total: €${(order['totalPaid'] as double).toStringAsFixed(2)}'),
              trailing: Text(order['status'] ?? 'N/A', style: TextStyle(color: order['status'] == 'Processing' ? accentColor : Colors.green)),
            );
          },
        );
      },
    );
  }
}

class SellingHistoryTab extends StatelessWidget {
  final String userId;
  const SellingHistoryTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: MongoDBService.getSellingHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('No products listed yet. Register as a seller!', style: bodyTextStyle));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            // NOTE: product.status.toShortString() now relies on the extension being defined in lib/models/product.dart
            return ListTile(
              leading: const Icon(Icons.inventory, color: primaryColor),
              title: Text(product.name),
              subtitle: Text('Stock: ${product.stockCount} | Status: ${product.status.toShortString()}'),
              trailing: IconButton(
                icon: const Icon(Icons.flag, color: Colors.red),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportProductPage(
                        productId: product.id,
                        userId: userId,
                      ),
                    ),
                  );
                },
                tooltip: 'Report Product',
              ),
            );
          },
        );
      },
    );
  }
}

class InvestmentHistoryTab extends StatelessWidget {
  final String userId;
  const InvestmentHistoryTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDBService.getInvestmentHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final investments = snapshot.data ?? [];
        if (investments.isEmpty) {
          return const Center(child: Text('No investment history found.', style: bodyTextStyle));
        }

        return ListView.builder(
          itemCount: investments.length,
          itemBuilder: (context, index) {
            final investment = investments[index];
            final sellerId = investment['sellerId'] as String? ?? 'N/A';
            final amount = investment['amount'] as num? ?? 0;

            return ListTile(
              leading: const Icon(Icons.trending_up, color: accentColor),
              title: Text('Investment in Seller: ${sellerId.substring(0, 8)}...'),
              subtitle: Text('Amount: €${amount.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action 1: View Seller Profile (Placeholder)
                  IconButton(
                    icon: const Icon(Icons.business_center, color: primaryColor),
                    tooltip: 'View Seller Profile',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing Seller Profile for ${sellerId.substring(0, 8)}...')),
                      );
                    },
                  ),
                  // Action 2: Chat with Seller
                  IconButton(
                    icon: const Icon(Icons.chat, color: primaryColor),
                    tooltip: 'Chat with Seller',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(sellerId: sellerId)));
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================
// User Profile Page (Tab 4) - Detailed Implementation
// =============================================================

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await MongoDBService.getUser(widget.userId);
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    if (_userData == null) {
      return Scaffold(body: Center(child: Text(_errorMessage.isNotEmpty ? _errorMessage : 'User data not found.', style: bodyTextStyle)));
    }

    final String fullName = '${_userData!['firstName']} ${_userData!['lastName']}';
    final List<String> badges = (_userData!['badges'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      body: Column(
        children: [
          // --- User Details and Badges ---
          _buildUserDetailsHeader(fullName, widget.userId, badges),

          // --- Tabs ---
          TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: textColor,
            tabs: const [
              Tab(text: 'Purchases'),
              Tab(text: 'Selling'),
              Tab(text: 'Investments'),
            ],
          ),

          // --- Tab Content (History) ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Purchase History (Orders)
                PurchaseHistoryTab(userId: widget.userId),
                // 2. Selling History (Products)
                SellingHistoryTab(userId: widget.userId),
                // 3. Investment History (with Chat/View Seller Profile)
                InvestmentHistoryTab(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsHeader(String name, String userId, List<String> badges) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 50, color: accentColor),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: headingStyle.copyWith(fontSize: 22)),
                  Text('User ID: ${userId.substring(0, 8)}...', style: bodyTextStyle.copyWith(color: Colors.grey)),
                  Text('Points: ${_userData!['ecoPoints'] ?? 0}', style: bodyTextStyle.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Badges Obtained:', style: headingStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: badges.map((badge) => Chip(
              label: Text(badge, style: const TextStyle(color: Colors.white)),
              backgroundColor: primaryColor,
              avatar: const Icon(Icons.star, color: Colors.yellow, size: 18),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Home Content Page (Tab 2)
// =============================================================

class HomePageContent extends StatelessWidget {
  final Widget Function({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String description,
  required Color backgroundColor,
  required String buttonText,
  required VoidCallback onButtonPressed,
  }) buildFeatureCard;

  final String userId;
  final bool isRegisteredSeller;

  const HomePageContent({
    super.key,
    required this.buildFeatureCard,
    required this.userId,
    required this.isRegisteredSeller,
  });

  @override
  Widget build(BuildContext context) {
    // The actual button actions here will switch the bottom navigation index
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Buy Feature Card ---
        buildFeatureCard(
          context: context,
          icon: Icons.storefront,
          title: 'Buy Sustainable Products',
          description: 'Explore a curated marketplace of verified eco-friendly goods from ethical sellers.',
          backgroundColor: secondaryColor.withOpacity(0.3),
          buttonText: 'Start Shopping',
          onButtonPressed: () {
            // NOTE: This action is handled by the calling function _buildFeatureCard
          },
        ),
        const SizedBox(height: 24),

        // --- Sell Feature Card ---
        buildFeatureCard(
          context: context,
          icon: isRegisteredSeller ? Icons.dashboard : Icons.add_business,
          title: isRegisteredSeller ? 'Seller Dashboard' : 'Become a Seller',
          description: isRegisteredSeller
              ? 'Manage your listings, track performance, and update your inventory.'
              : 'Register your eco-business and start selling your sustainable products today.',
          backgroundColor: accentColor.withOpacity(0.3),
          buttonText: isRegisteredSeller ? 'Go to Dashboard' : 'Register Now',
          onButtonPressed: () {
            // NOTE: This action is handled by the calling function _buildFeatureCard
          },
        ),
        const SizedBox(height: 24),

        // --- Invest Feature Card ---
        buildFeatureCard(
          context: context,
          icon: Icons.trending_up,
          title: 'Invest in Impact',
          description: 'Fund high-potential, verified eco-businesses and track your positive environmental impact.',
          backgroundColor: primaryColor.withOpacity(0.3),
          buttonText: 'Explore Investments',
          onButtonPressed: () {
            // NOTE: This action is handled by the calling function _buildFeatureCard
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// =============================================================
// UserHomePage - The Main Shell with Bottom Navigation
// =============================================================

class UserHomePage extends StatefulWidget {
  final String userId;
  final String userRole; // 'buyer', 'seller', or 'admin'
  const UserHomePage({super.key, required this.userId, required this.userRole});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // Start on the Home tab (index 2)
  int _selectedIndex = 2;
  Seller? _seller;
  bool _isLoading = true;
  String _errorMessage = '';

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadSellerStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerStatus() async {
    if (widget.userRole == 'admin') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final seller = await MongoDBService.getSeller(widget.userId);
      setState(() {
        _seller = seller;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load seller status: $e';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 💡 ENHANCEMENT: Use a more dramatic curve for modern navigation feel
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500), // Slightly slower animation
      curve: Curves.easeInOutExpo, // More punchy, modern curve
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    // Corrected for potential RenderFlex overflow issues
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: backgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: primaryColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: headingStyle.copyWith(fontSize: 24, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Logic to navigate via the button:
                final targetIndex = title.contains('Buy') ? 0 : title.contains('Invest') ? 1 : 3;
                _onItemTapped(targetIndex);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              child: Text(buttonText, style: buttonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _pages(String userId, bool isSellerRegistered) {
    return [
      // 0. Buy (Shopping Bag)
      const BuyPage(),

      // 1. Investor (Trending Up)
      const InvestPage(),

      // 2. Home (Center)
      HomePageContent(
        buildFeatureCard: _buildFeatureCard,
        userId: userId,
        isRegisteredSeller: isSellerRegistered,
      ),

      // 3. Seller (Store) - Conditional Page
      isSellerRegistered
          ? SellerDashboardPage(userId: userId)
          : SellerRegistrationPage(userId: userId, onRegistrationComplete: _loadSellerStatus),

      // 4. User Profile (Person)
      UserProfilePage(userId: userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == 'admin') {
      return const Scaffold(
        body: Center(
            child: Text("Welcome Admin. Please navigate via the Admin Dashboard.", style: headingStyle)
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final isSellerRegistered = _seller != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verdant Vault', style: appTitleStyle.copyWith(fontSize: 24)),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (widget.userRole == 'buyer' || widget.userRole == 'seller')
            Consumer<CartService>(
              builder: (context, cart, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // 🎯 This call is now correct because CartPage accepts userId
                            builder: (context) => CartPage(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                    if (cart.totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: primaryColor),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        // Remove onPageChanged here to prevent conflicting state updates from PageView and onTap
        // onPageChanged: _onItemTapped,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages(widget.userId, isSellerRegistered),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Buy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Invest',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          selectedItemColor: primaryColor,
          unselectedItemColor: textColor.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          elevation: 10,
        ),
      ),
    );
  }
}