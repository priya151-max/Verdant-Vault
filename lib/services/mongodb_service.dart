// lib/services/mongodb_service.dart (FINAL CORRECTED CODE - WITH ENHANCED SCHEMA)

import 'package:mongo_dart/mongo_dart.dart';
import 'package:verdant_vault/models/product.dart';
import 'package:verdant_vault/models/seller.dart';
import 'package:verdant_vault/models/report.dart'; // Placeholder model
import 'package:verdant_vault/constants.dart'; // Needs mongoDBUri and kBackendBaseUrl
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MongoDBService {
  static late Db _db;

  // Collection Names (Schema Definitions)
  static const String _usersCollection = 'users';
  static const String _sellersCollection = 'sellers';
  static const String _productsCollection = 'products';
  static const String _ordersCollection = 'orders'; // Contains comprehensive transaction/delivery details
  static const String _investmentsCollection = 'investments';
  static const String _payoutsCollection = 'payouts'; // NEW: Placeholder for seller payouts

  // --- INITIALIZATION ---
  static Future<void> init() async {
    try {
      _db = await Db.create(mongoDBUri);
      await _db.open();
      print('Connected to MongoDB successfully! 🟢');
      await _loadDemoData();
    } catch (e) {
      print('Error connecting to MongoDB: $e 🔴');
      rethrow;
    }
  }

  static Future<void> close() async {
    if (_db.isConnected) {
      await _db.close();
      print('MongoDB connection closed.');
    }
  }

  // --- DEMO DATA LOAD (Enhanced with Shipping and Payment Details) ---
  static Future<void> _loadDemoData() async {
    final userCount = await _db.collection(_usersCollection).count();
    if (userCount == 0) {
      const Uuid uuid = Uuid();
      // Using a constant hash for demo environment
      const commonHash = '5f822a101b0f512760f331904a4ec410978377d64397a66b57743d78c3b4295e';

      final adminUser = {
        'id': uuid.v4(),
        'firstName': 'Vault',
        'lastName': 'Admin',
        'email': 'admin@gmail.com',
        'phone': '123-456-7890',
        'passwordHash': commonHash,
        'isAdmin': true,
        'ecoPoints': 0,
        'badges': ['Administrator'],
      };

      final sellerUserId = 'seller-user-id'; // Use a fixed ID for the seller
      final buyerUser = {
        'id': 'buyer-user-id',
        'firstName': 'Eco',
        'lastName': 'Buyer',
        'email': 'buyer@verdantvault.com',
        'phone': '098-765-4321',
        'passwordHash': commonHash,
        'isAdmin': false,
        'ecoPoints': 500,
        'address': '123 Green Street, Earth City',
        'badges': ['Eco-Initiate', 'First Purchase'],
        'isSeller': true, // Mark as seller for demo history
      };

      final demoSeller = Seller(
        userId: sellerUserId,
        businessName: 'Eco-Demo Seller',
        businessDescription: 'Demo seller for testing history.',
        address: '456 Commerce Rd, Demo City',
        creditScore: 850,
        isVisibleToInvestors: true,
      ).toMap();

      // Demo Order (Purchase History) - ENHANCED STRUCTURE
      final demoOrder = {
        'orderId': 'order-demo-123',
        'userId': 'buyer-user-id', // The buyer who made the purchase
        'sellerId': sellerUserId, // The primary seller for this order (simplified)
        'timestamp': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'items': [
          {'productId': 'p1', 'quantity': 2, 'price': 5.0},
        ],
        'totalPaid': 10.0 + 5.0, // items + shipping
        'status': 'Completed',
        'paymentStatus': 'Paid',
        'shippingAddress': '123 Green Street, Earth City',
        'shippingTracking': 'SHIP-12345',
        'shippingCost': 5.0,
      };

      // Demo Order 2 (Sale for the primary seller) - ENHANCED STRUCTURE
      final demoOrder2 = {
        'orderId': 'order-demo-456',
        'userId': 'another-buyer-id',
        'sellerId': sellerUserId, // The seller we are tracking
        'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'items': [
          {'productId': 'p3', 'quantity': 5, 'price': 2.50},
        ],
        'totalPaid': 12.50 + 3.0, // items + shipping
        'status': 'Processing', // Example of a current order
        'paymentStatus': 'Paid',
        'shippingAddress': '789 Test Lane, Test Town',
        'shippingTracking': null,
        'shippingCost': 3.0,
      };

      // Demo Investment History
      final demoInvestment = {
        'investmentId': 'inv-demo-123',
        'userId': 'buyer-user-id',
        'sellerId': 'seller-user-id-2', // A different seller (placeholder)
        'amount': 500.0,
        'timestamp': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      };


      await _db.collection(_usersCollection).insert(adminUser);
      await _db.collection(_usersCollection).insert(buyerUser);
      await _db.collection(_sellersCollection).insert(demoSeller);
      await _db.collection(_ordersCollection).insert(demoOrder);
      await _db.collection(_ordersCollection).insert(demoOrder2);
      await _db.collection(_investmentsCollection).insert(demoInvestment);
      print('Demo Data (Users, Seller, Order, Investment) created ✅');
    }
  }

  // --- USER AUTHENTICATION & REGISTRATION ---
  static Future<Map<String, dynamic>?> authenticateUser(
      String email, String passwordHash) async {
    final user = await _db.collection(_usersCollection).findOne(
      where.eq('email', email).eq('passwordHash', passwordHash),
    );
    if (user != null) {
      // Use the string 'id' field if it exists, otherwise use the ObjectId
      user['id'] = user['id'] ?? user['_id'].toHexString();
    }
    return user;
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final user = await _db.collection(_usersCollection).findOne(where.eq('id', userId));
    return user;
  }

  static Future<void> updateEcoPoints(String userId, int newPoints) async {
    await _db.collection(_usersCollection).updateOne(
      where.eq('id', userId),
      ModifierBuilder().set('ecoPoints', newPoints),
    );
  }

  static Future<void> registerUser(Map<String, dynamic> userData) async {
    await _db.collection(_usersCollection).insertOne({
      ...userData,
      'isAdmin': false,
      'isSeller': false,
      'ecoPoints': 0,
    });
  }

  static Future<bool> isEmailRegistered(String email) async {
    final count = await _db.collection(_usersCollection).count(where.eq('email', email));
    return count > 0;
  }

  // --- SELLER MANAGEMENT ---
  static Future<void> createSeller(Seller seller) async {
    await _db.collection(_sellersCollection).insertOne(seller.toMap());
  }

  static Future<List<Seller>> getVisibleSellers() async {
    final List<Map<String, dynamic>> results = await _db.collection(_sellersCollection)
        .find(where.eq('isVisibleToInvestors', true).sortBy('creditScore', descending: true))
        .toList();
    return results.map((map) => Seller.fromMap(map)).toList();
  }

  static Future<Seller?> getSeller(String userId) async {
    final map = await _db.collection(_sellersCollection).findOne(where.eq('userId', userId));
    return map != null ? Seller.fromMap(map) : null;
  }

  // --- PRODUCT MANAGEMENT ---

  static Future<void> createProduct(Product product) async {
    await _db.collection(_productsCollection).insertOne(product.toMap());
  }

  static Future<void> updateProduct(Product product) async {
    await _db.collection(_productsCollection).updateOne(
      where.eq('id', product.id),
      product.toUpdateMap(),
    );
  }

  static Future<void> deleteProduct(String productId) async {
    await _db.collection(_productsCollection).remove(where.eq('id', productId));
  }

  static Future<Product?> getProductById(String productId) async {
    final map = await _db.collection(_productsCollection).findOne(where.eq('id', productId));
    return map != null ? Product.fromMap(map) : null;
  }

  // 🚨 CORRECTED getProducts METHOD 🚨
  static Future<List<Product>> getProducts(Map<String, dynamic> query) async {
    SelectorBuilder selector = where;

    if (query.containsKey('status')) {
      final status = query['status'] as ProductStatus;
      selector = selector.eq('status', status.toShortString());
    }
    if (query.containsKey('sellerId')) {
      final sellerId = query['sellerId'] as String;
      selector = selector.eq('sellerId', sellerId);
    }
    if (query.containsKey('category') && query['category'] != 'All') {
      final category = query['category'] as String;
      selector = selector.eq('category', category);
    }

    // Apply default 'approved' status ONLY IF:
    // 1. No specific status was already requested (!query.containsKey('status'))
    // 2. It is not a seller's personal view (!query.containsKey('sellerId'))
    // 3. It is not an admin's view (where all statuses are required)
    if (!query.containsKey('status') && !query.containsKey('sellerId') && !(query.containsKey('isAdminView') == true)) {
      selector = selector.eq('status', ProductStatus.approved.toShortString());
    }

    selector = selector.sortBy('createdDate', descending: true);

    final List<Map<String, dynamic>> results = await _db.collection(_productsCollection)
        .find(selector)
        .toList();

    return results.map((map) => Product.fromMap(map)).toList();
  }

  // --- 🚨 PRODUCT REPORTING LOGIC 🚨 ---

  static Future<void> reportProduct(String productId, String userId, String comment) async {
    final report = {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'comment': comment,
    };

    await _db.collection(_productsCollection).updateOne(
      where.eq('id', productId),
      ModifierBuilder().push('reports', report),
    );

    final updatedProductMap = await _db.collection(_productsCollection).findOne(
        where.eq('id', productId)
    );

    if (updatedProductMap != null) {
      final reports = updatedProductMap['reports'] as List? ?? [];
      final uniqueReporters = reports.map((r) => r['userId']).toSet().length;
      const int deletionThreshold = 5;

      if (uniqueReporters >= deletionThreshold) {
        await deleteProduct(productId);
        final sellerId = updatedProductMap['sellerId'];
        print('🚨 AUTO-DELETE TRIGGERED: Product ID $productId deleted due to reaching $deletionThreshold unique reports.');
      }
    }
  }


  // --- USER PROFILE HISTORY METHODS ---

  /// Fetches the user's purchase history (Orders)
  static Future<List<Map<String, dynamic>>> getPurchaseHistory(String userId) async {
    final results = await _db.collection(_ordersCollection)
        .find(where.eq('userId', userId).sortBy('timestamp', descending: true))
        .toList();
    return results;
  }

  /// Fetches the user's selling history (Products they own)
  static Future<List<Product>> getSellingHistory(String userId) async {
    final results = await _db.collection(_productsCollection)
        .find(where.eq('sellerId', userId).sortBy('createdDate', descending: true))
        .toList();
    return results.map((map) => Product.fromMap(map)).toList();
  }

  /// Fetches the sales (order) history where the given userId is the seller.
  static Future<List<Map<String, dynamic>>> getSellerSalesHistory(String sellerId) async {
    // Only fetch orders where the seller is the one being tracked AND the order is completed/paid
    final results = await _db.collection(_ordersCollection)
        .find(where.eq('sellerId', sellerId).eq('paymentStatus', 'Paid').sortBy('timestamp', descending: true))
        .toList();

    return results;
  }


  /// Fetches the user's investment history
  static Future<List<Map<String, dynamic>>> getInvestmentHistory(String userId) async {
    final results = await _db.collection(_investmentsCollection)
        .find(where.eq('userId', userId).sortBy('timestamp', descending: true))
        .toList();
    return results;
  }

  // --- ORDER AND PAYMENT LOGIC (Transaction & Delivery Management) ---

  /// Creates a new order document in the database and updates product stock.
  /// The orderData should now include shipping address and cost.
  static Future<void> createOrder(Map<String, dynamic> orderData) async {
    // The orderData is expected to be a map containing:
    // 'userId', 'sellerId', 'items', 'totalPaid', 'shippingAddress', 'shippingCost'

    // 1. Insert order into a dedicated 'orders' collection
    final order = {
      'orderId': const Uuid().v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'Processing', // Initial status
      'paymentStatus': 'Awaiting Payment', // Initial payment status
      'shippingTracking': null, // Initial tracking info
      ...orderData,
    };
    await _db.collection(_ordersCollection).insert(order);

    // 2. Simulate inventory update (decrement stock)
    for (var item in orderData['items']) {
      final productId = item['productId'];
      final quantity = item['quantity'];

      await _db.collection(_productsCollection).updateOne(
        where.eq('id', productId),
        ModifierBuilder().inc('stockCount', -quantity), // Decrement stock
      );
    }
  }

  // NEW: Method for sellers to update order details
  static Future<void> updateOrderStatusAndShipping({
    required String orderId,
    String? status,
    String? trackingNumber,
  }) async {
    final modifier = ModifierBuilder();

    if (status != null) {
      modifier.set('status', status);
    }

    if (trackingNumber != null) {
      modifier.set('shippingTracking', trackingNumber);
      // Automatically update status to 'Shipped' if tracking is added
      if (status == null) {
        modifier.set('status', 'Shipped');
      }
    }

    await _db.collection(_ordersCollection).updateOne(
      where.eq('orderId', orderId),
      modifier,
    );
  }


  // --- IMAGE UPLOAD FUNCTION (Requires a separate backend server) ---
  static Future<List<String>> uploadImages(List<String> imagePaths) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/upload-images');
    final request = http.MultipartRequest('POST', uri);
    if (imagePaths.isEmpty) return [];

    for (var path in imagePaths) {
      if (path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
            filename: path.split('/').last,
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('urls') && data['urls'] is List) {
          return (data['urls'] as List).cast<String>();
        } else {
          throw Exception('Backend did not return image URLs in expected format (missing "urls" key).');
        }
      } else {
        throw Exception('Image upload failed with status ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Connection error: Ensure your backend server is running and accessible at $kBackendBaseUrl.');
    } catch (e) {
      rethrow;
    }
  }
}