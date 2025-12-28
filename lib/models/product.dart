// lib/models/product.dart
import 'package:uuid/uuid.dart'; // Note: Uuid is not strictly used inside this file, but the import is retained.

// Status controls visibility: only 'approved' products are shown to buyers/investors.
// This enum is kept simple and will be converted to/from String when interacting with MongoDB.
enum ProductStatus {
  pending, // Only visible to Seller/Admin (Default state upon creation)
  approved, // Visible to all users
  rejected, // Only visible to Seller/Admin
  deactivated, // Approved then manually taken off market by Seller/Admin
}

// A simple utility to convert enum to string and vice versa
extension ProductStatusExtension on ProductStatus {
  String toShortString() => name;
}

// Helper function to safely convert a string from the database back to an enum
ProductStatus productStatusFromString(String status) {
  try {
    return ProductStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
    );
  } catch (e) {
    // Default to pending if the status is not recognized
    return ProductStatus.pending;
  }
}

class Product {
  String id;
  String name;
  String category;
  String sellerId;
  double price;
  String description;
  int stockCount;
  List<String> sustainabilityTags;
  List<String> imageUrls;
  ProductStatus status;
  String? adminRemarks; // Reason for rejection or notes
  DateTime createdDate;
  // NOTE: Assuming report field is managed separately in the MongoDBService

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellerId,
    required this.price,
    required this.description,
    required this.stockCount,
    required this.sustainabilityTags,
    required this.imageUrls,
    this.status = ProductStatus.pending,
    this.adminRemarks,
    required this.createdDate,
  });

  // Helper method for immutable object updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? sellerId,
    double? price,
    String? description,
    int? stockCount,
    List<String>? sustainabilityTags,
    List<String>? imageUrls,
    ProductStatus? status,
    String? adminRemarks,
    DateTime? createdDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      price: price ?? this.price,
      description: description ?? this.description,
      stockCount: stockCount ?? this.stockCount,
      sustainabilityTags: sustainabilityTags ?? this.sustainabilityTags,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  // Factory constructor to create a Product object from a MongoDB document (Map)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      sellerId: map['sellerId'] as String,
      price: (map['price'] as num).toDouble(), // MongoDB stores numbers as num
      description: map['description'] as String,
      stockCount: map['stockCount'] as int,
      sustainabilityTags: (map['sustainabilityTags'] as List? ?? []).cast<String>(),
      imageUrls: (map['imageUrls'] as List? ?? []).cast<String>(),
      status: productStatusFromString(map['status'] as String),
      adminRemarks: map['adminRemarks'] as String?,
      createdDate: DateTime.parse(map['createdDate'] as String),
    );
  }

  // Method to convert the Product object to a MongoDB document (Map) for insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sellerId': sellerId,
      'price': price,
      'description': description,
      'stockCount': stockCount,
      'sustainabilityTags': sustainabilityTags,
      'imageUrls': imageUrls,
      'status': status.toShortString(), // Store enum as string
      'adminRemarks': adminRemarks,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Correct update map using $set for safe MongoDB updates.
  Map<String, dynamic> toUpdateMap() {
    return {
      r'$set': {
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'stockCount': stockCount,
        'sustainabilityTags': sustainabilityTags,
        'imageUrls': imageUrls,
        'status': status.toShortString(),
        'adminRemarks': adminRemarks,
      },
    };
  }
}