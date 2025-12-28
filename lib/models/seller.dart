// lib/models/seller.dart

class Seller {
  // Assuming the user is stored in a separate 'users' collection,
  // the 'userId' links the Seller profile to the user's login account.
  String userId;
  String businessName;
  String businessDescription;
  String address;
  double creditScore;
  bool isVisibleToInvestors;
  List<String> productIds; // List of product IDs associated with this seller

  Seller({
    required this.userId,
    required this.businessName,
    required this.businessDescription,
    required this.address,
    this.creditScore = 0.0,
    this.isVisibleToInvestors = false,
    List<String>? productIds,
  }) : productIds = productIds ?? [];

  // Add copyWith method to the Seller class to allow immutable updates
  Seller copyWith({
    String? userId,
    String? businessName,
    String? businessDescription,
    String? address,
    double? creditScore,
    bool? isVisibleToInvestors,
    List<String>? productIds,
  }) {
    return Seller(
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      address: address ?? this.address,
      creditScore: creditScore ?? this.creditScore,
      isVisibleToInvestors: isVisibleToInvestors ?? this.isVisibleToInvestors,
      productIds: productIds ?? this.productIds,
    );
  }

  // Factory constructor to create a Seller object from a MongoDB document (Map)
  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      userId: map['userId'] as String,
      businessName: map['businessName'] as String,
      businessDescription: map['businessDescription'] as String? ?? '', // Handle potential null/missing
      address: map['address'] as String? ?? '', // Handle potential null/missing
      creditScore: (map['creditScore'] as num?)?.toDouble() ?? 0.0,
      isVisibleToInvestors: map['isVisibleToInvestors'] as bool? ?? false,
      productIds: (map['productIds'] as List?)?.cast<String>() ?? [],
    );
  }

  // Method to convert the Seller object to a MongoDB document (Map) for INSERT
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'address': address,
      'creditScore': creditScore,
      'isVisibleToInvestors': isVisibleToInvestors,
      'productIds': productIds,
    };
  }

  // Correct toUpdateMap() method using $set for safe MongoDB updates
  Map<String, dynamic> toUpdateMap() {
    return {
      r'$set': {
        'businessName': businessName,
        'businessDescription': businessDescription,
        'address': address,
        'creditScore': creditScore,
        'isVisibleToInvestors': isVisibleToInvestors,
        'productIds': productIds,
      },
    };
  }
}