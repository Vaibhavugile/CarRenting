import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;

  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;

  final String? businessId;
  final String? branchId;
  final String? branchCode;

  final String role;

  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.businessId,
    this.branchId,
    this.branchCode,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      businessId: data['businessId'],
      branchId: data['branchId'],
      branchCode: data['branchCode'],
      role: data['role'] ?? 'owner',
      isActive: data['isActive'] ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'businessId': businessId,
      'branchId': branchId,
      'branchCode': branchCode,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}