import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final DateTime createdAt;
  final DateTime? purchasedAt;
  final bool isPurchased;
  final String deviceModel;
  final String osVersion;

  User({
    required this.userId,
    required this.createdAt,
    this.purchasedAt,
    required this.isPurchased,
    required this.deviceModel,
    required this.osVersion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasedAt: (json['purchasedAt'] as Timestamp?)?.toDate(),
      isPurchased: json['isPurchased'] ?? false,
      deviceModel: json['deviceModel'] ?? '',
      osVersion: json['osVersion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'purchasedAt': purchasedAt,
      'isPurchased': isPurchased,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
    };
  }
}
