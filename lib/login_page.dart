// lib/login_page.dart (FINAL CORRECTED VERSION - NO DEFAULT CREDENTIALS)
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // REQUIRED for SHA256 hashing
import 'package:verdant_vault/services/mongodb_service.dart';

import 'registration_page.dart';
import 'user_home_page.dart';
import 'admin_dashboard_page.dart';
import 'constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // ❌ REMOVED: Default admin credentials should not be here.
    // _emailController.text = 'admin@gmail.com';
    // _passwordController.text = 'admin@1234';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ CRITICAL FIX: Function to hash the password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> login() async {
    setState(() {
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required.';
      });
      return;
    }

    // 1. Hash the user's input password
    final hashedPassword = _hashPassword(password);

    try {
      // 2. Authenticate the user against the database using the HASH
      final user = await MongoDBService.authenticateUser(email, hashedPassword);

      if (user != null) {
        if (mounted) {
          final userId = user['id'] as String;
          final isAdmin = user['isAdmin'] as bool? ?? false;
          final isSeller = user['isSeller'] as bool? ?? false; // Check for seller status

          // Determine user role for navigation
          String userRole;
          if (isAdmin) {
            userRole = 'admin';
          } else if (isSeller) {
            userRole = 'seller';
          } else {
            userRole = 'buyer';
          }


          if (isAdmin) {
            // Navigate to Admin Dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            );
          } else {
            // Navigate to User Home Page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => UserHomePage(userId: userId, userRole: userRole)),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during login: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verdant Vault Login'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Welcome Back', style: headingStyle.copyWith(color: primaryColor)),
                          const SizedBox(height: 10),
                          Text('Enter your credentials to continue', style: bodyTextStyle),
                          const SizedBox(height: 30),
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: primaryColor.withOpacity(0.7)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: primaryColor.withOpacity(0.7)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Remember Me
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              Text('Remember Me', style: bodyTextStyle),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50), // Full width button
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
                            ),
                            child: const Text('Login', style: buttonTextStyle),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegistrationPage()));
                            },
                            child: const Text(
                              'Sign Up / New User',
                              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(_errorMessage,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
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