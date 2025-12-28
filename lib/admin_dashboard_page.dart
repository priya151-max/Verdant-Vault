// lib/admin_dashboard_page.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:verdant_vault/login_page.dart'; // To navigate back to login
import 'constants.dart';
import 'package:verdant_vault/admin_product_management_page.dart'; // Keep the import for the actual page

// Placeholder Pages for Admin Sections
class AdminDashboardOverviewPage extends StatelessWidget {
  const AdminDashboardOverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dashboard Overview & Stats', style: subheadingStyle));
  }
}

// REMOVED THE DUPLICATE DEFINITION of AdminProductManagementPage
// The class is imported from 'package:verdant_vault/admin_product_management_page.dart'.

class AdminSellerBuyerManagementPage extends StatelessWidget {
  const AdminSellerBuyerManagementPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Seller & Buyer Management', style: subheadingStyle));
  }
}

class AdminCreditEcoPointsPage extends StatelessWidget {
  const AdminCreditEcoPointsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Credit Score & Eco-Points', style: subheadingStyle));
  }
}

class AdminMLAnalyticsPage extends StatelessWidget {
  const AdminMLAnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('ML & Analytics Insights', style: subheadingStyle));
  }
}

class AdminInvestorManagementPage extends StatelessWidget {
  const AdminInvestorManagementPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Investor Management', style: subheadingStyle));
  }
}

class AdminReportsAnalyticsPage extends StatelessWidget {
  const AdminReportsAnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports & Analytics', style: subheadingStyle));
  }
}

class AdminSystemSettingsPage extends StatelessWidget {
  const AdminSystemSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('System & Settings', style: subheadingStyle));
  }
}

class AdminSecurityCompliancePage extends StatelessWidget {
  const AdminSecurityCompliancePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Security & Compliance', style: subheadingStyle));
  }
}

class AdminContentCommunityPage extends StatelessWidget {
  const AdminContentCommunityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Content & Community', style: subheadingStyle));
  }
}


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0; // Index for the selected drawer item
  String _currentTitle = 'Admin Dashboard'; // Title to display in AppBar

  // List of pages/sections for the admin dashboard
  late final List<Widget> _adminPages = [
    const AdminDashboardOverviewPage(),
    const AdminProductManagementPage(), // Now using the imported class
    const AdminSellerBuyerManagementPage(),
    const AdminCreditEcoPointsPage(),
    const AdminMLAnalyticsPage(),
    const AdminInvestorManagementPage(),
    const AdminReportsAnalyticsPage(),
    const AdminSystemSettingsPage(),
    const AdminSecurityCompliancePage(),
    const AdminContentCommunityPage(),
  ];

  // List of titles corresponding to the pages
  final List<String> _adminPageTitles = [
    'Dashboard Overview',
    'Product Management',
    'Seller & Buyer Management',
    'Credit Score & Eco-Points',
    'ML & Analytics Insights',
    'Investor Management',
    'Reports & Analytics',
    'System & Settings',
    'Security & Compliance',
    'Content & Community',
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentTitle = _adminPageTitles[index];
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Container( // Wrap Drawer content in Container for gradient
          decoration: const BoxDecoration(
            gradient: backgroundGradient, // Using your existing background gradient
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Admin Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: buttonGradient, // Use your button gradient for the header
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Panel',
                      style: appTitleStyle.copyWith(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
              // Drawer Items
              _buildDrawerItem(0, Icons.dashboard, 'Dashboard Overview'),
              _buildDrawerItem(1, Icons.inventory_2, 'Product Management'),
              _buildDrawerItem(2, Icons.people, 'Seller & Buyer Management'),
              _buildDrawerItem(3, Icons.score, 'Credit Score & Eco-Points'),
              _buildDrawerItem(4, Icons.lightbulb, 'ML & Analytics Insights'),
              _buildDrawerItem(5, Icons.account_balance_wallet, 'Investor Management'),
              _buildDrawerItem(6, Icons.bar_chart, 'Reports & Analytics'),
              _buildDrawerItem(7, Icons.settings, 'System & Settings'),
              _buildDrawerItem(8, Icons.security, 'Security & Compliance'),
              _buildDrawerItem(9, Icons.campaign, 'Content & Community'),

              const Divider(color: textColor), // Separator
              ListTile(
                leading: Icon(Icons.logout, color: primaryColor),
                title: Text('Log Out', style: bodyTextStyle),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Container( // Main body also uses gradient
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: _adminPages[_selectedIndex], // Display the selected admin page
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? secondaryColor : primaryColor),
      title: Text(
        title,
        style: _selectedIndex == index
            ? subheadingStyle.copyWith(color: secondaryColor, fontWeight: FontWeight.bold)
            : bodyTextStyle.copyWith(color: textColor),
      ),
      onTap: () => _onDrawerItemTapped(index),
      selected: _selectedIndex == index,
      selectedTileColor: primaryColor.withValues(alpha: 0.1), // Subtle highlight for selected
    );
  }
}