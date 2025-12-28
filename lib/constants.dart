// lib/constants.dart (FINAL COMPLETE CODE)

import 'package:flutter/material.dart';

// --------------------------------------------------------------------------
// 1. Connection Strings and Configuration
// --------------------------------------------------------------------------

// MongoDB Atlas URI (Password percent-encoded: '@' -> '%40')
// This URI connects to your remote MongoDB Atlas cluster.
const String mongoDBUri = 'mongodb+srv://verdantvault151_db_user:priya%401234@cluster0.ajwronn.mongodb.net/verdant_vault?retryWrites=true&w=majority';

// Backend API URL
// Use 'http://10.0.2.2:3000' for Android Emulator to access the host's localhost.
// Use 'http://localhost:3000' for iOS Simulator/Web/Desktop.
const String kBackendBaseUrl = 'http://10.0.2.2:3000';


// --------------------------------------------------------------------------
// 2. Color Palette
// --------------------------------------------------------------------------

const Color primaryColor = Color(0xFF1E8858); // Earthy Deep Green 🌿
const Color secondaryColor = Color(0xFFB5E8A9); // Soft Eco Green
const Color accentColor = Color(0xFFE8D0B5); // Warm Beige (for highlights/accents)
const Color textColor = Color(0xFF424242); // Dark grey for text
const Color lightTextColor = Color(0xFFF5F5F5); // Light grey for text on dark backgrounds
const Color cardColor = Colors.white; // White for cards


// --------------------------------------------------------------------------
// 3. Gradients
// --------------------------------------------------------------------------

const LinearGradient backgroundGradient = LinearGradient(
  colors: [Color(0xFFF0F4F8), Color(0xFFE0E7EB)], // Light background gradient
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient buttonGradient = LinearGradient(
  colors: [primaryColor, Color(0xFF4CAF50)], // Green button gradient
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);


// --------------------------------------------------------------------------
// 4. Text Styles
// --------------------------------------------------------------------------

const TextStyle appTitleStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: primaryColor,
);

const TextStyle headingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textColor,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: textColor,
);

const TextStyle bodyTextStyle = TextStyle(
  fontSize: 16,
  color: textColor,
);

const TextStyle buttonTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white, // White text for primary buttons
);

const TextStyle ecoCreditTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: primaryColor,
);


// --------------------------------------------------------------------------
// 5. Border Radius
// --------------------------------------------------------------------------

const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(20)); // 2xl rounded corners
const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(12));
const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(15));


// --------------------------------------------------------------------------
// 6. Category List for Buy/Sell Filters
// --------------------------------------------------------------------------

const List<String> ecoCategories = [
  'All',
  'Apparel',
  'Home & Decor',
  'Electronics',
  'Beauty & Personal Care',
  'Food & Beverage',
  'Services',
  'Upcycled Goods',
  'Renewable Energy',
];