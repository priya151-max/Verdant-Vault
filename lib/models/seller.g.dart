// lib/models/seller.dart

/// Represents a seller profile associated with a user account.
/// Each seller can have a list of product IDs linked to their store.
class Seller {
  /// The ID of the user that owns this seller account.
  String userId;

  /// The business/store name of the seller.
  String businessName;

  /// A short description of the seller’s eco-friendly business.
  String businessDescription;

  /// Physical or operational address of the business.
  String address;

  /// Seller’s performance or credibility score (used for eco-ratings or investor trust).
  double creditScore;

  /// Whether the seller is visible to investors on the platform.
  bool isVisibleToInvestors;

  /// The list of product IDs this seller has published.
  List<String> productIds;

  /// Optional verification and badges system fields (extendable).
  bool isVerified;
  List<String> badges;

  Seller({
    required this.userId,
    required this.businessName,
    required this.businessDescription,
    required this.address,
    this.creditScore = 0.0,
    this.isVisibleToInvestors = false,
    List<String>? productIds,
    this.isVerified = false,
    List<String>? badges,
  })  : productIds = productIds ?? [],
        badges = badges ?? [];

  /// Allows easy immutable updates for UI/logic
  Seller copyWith({
    String? userId,
    String? businessName,
    String? businessDescription,
    String? address,
    double? creditScore,
    bool? isVisibleToInvestors,
    List<String>? productIds,
    bool? isVerified,
    List<String>? badges,
  }) {
    return Seller(
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      address: address ?? this.address,
      creditScore: creditScore ?? this.creditScore,
      isVisibleToInvestors: isVisibleToInvestors ?? this.isVisibleToInvestors,
      productIds: productIds ?? this.productIds,
      isVerified: isVerified ?? this.isVerified,
      badges: badges ?? this.badges,
    );
  }

  /// Create a Seller object from a MongoDB document (Map)
  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      userId: map['userId']?.toString() ?? '',
      businessName: map['businessName']?.toString() ?? '',
      businessDescription: map['businessDescription']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      creditScore: (map['creditScore'] ?? 0).toDouble(),
      isVisibleToInvestors: map['isVisibleToInvestors'] ?? false,
      productIds: (map['productIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isVerified: map['isVerified'] ?? false,
      badges: (map['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  /// Convert a Seller object to a MongoDB document (Map) for insert operations
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'address': address,
      'creditScore': creditScore,
      'isVisibleToInvestors': isVisibleToInvestors,
      'productIds': productIds,
      'isVerified': isVerified,
      'badges': badges,
    };
  }

  /// Generate a MongoDB `$set` update document for partial updates
  Map<String, dynamic> toUpdateMap() {
    return {
      r'$set': {
        'businessName': businessName,
        'businessDescription': businessDescription,
        'address': address,
        'creditScore': creditScore,
        'isVisibleToInvestors': isVisibleToInvestors,
        'productIds': productIds,
        'isVerified': isVerified,
        'badges': badges,
      },
    };
  }

  @override
  String toString() {
    return 'Seller(businessName: $businessName, creditScore: $creditScore, verified: $isVerified)';
  }
}
