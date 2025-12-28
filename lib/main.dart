// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdant_vault/login_page.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';
import 'package:verdant_vault/services/cart_service.dart'; // REQUIRED: Import CartService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MongoDB Service initialization
  await MongoDBService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the App with the CartService provider (Fixes ProviderNotFoundException)
    return ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MaterialApp(
        title: 'Verdant Vault',
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Light grey/blue background
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(secondary: secondaryColor),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: primaryColor,
            titleTextStyle: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            labelStyle: const TextStyle(color: textColor),
            hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              elevation: 5,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // 2. 🎯 FIX: Using CardThemeData to satisfy the older SDK type requirement.
          cardTheme: CardThemeData(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
            color: cardColor,
            shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}