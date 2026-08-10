import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;

  final String businessId;
  final String branchCode;

  final String phone;
  final String name;

  final String? email;
  final String? address;

  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? licenseImageUrl;

  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImageUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.businessId,
    required this.branchCode,
    required this.phone,
    required this.name,
    this.email,
    this.address,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.licenseImageUrl,
    this.idProofType,
    this.idProofNumber,
    this.idProofImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CustomerModel(
      id: doc.id,

      businessId:
          data['businessId'] ?? '',

      branchCode:
          data['branchCode'] ?? '',

      phone:
          data['phone'] ?? '',

      name:
          data['name'] ?? '',

      email:
          data['email'],

      address:
          data['address'],

      licenseNumber:
          data['licenseNumber'],

      licenseExpiryDate:
          _dateFromFirestore(
        data['licenseExpiryDate'],
      ),

      licenseImageUrl:
          data['licenseImageUrl'],

      idProofType:
          data['idProofType'],

      idProofNumber:
          data['idProofNumber'],

      idProofImageUrl:
          data['idProofImageUrl'],

      createdAt:
          _dateFromFirestore(
            data['createdAt'],
          ) ??
          DateTime.now(),

      updatedAt:
          _dateFromFirestore(
            data['updatedAt'],
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'businessId':
          businessId,

      'branchCode':
          branchCode,

      'phone':
          phone,

      'name':
          name,

      'email':
          email,

      'address':
          address,

      'licenseNumber':
          licenseNumber,

      'licenseExpiryDate':
          licenseExpiryDate == null
              ? null
              : Timestamp.fromDate(
                  licenseExpiryDate!,
                ),

      'licenseImageUrl':
          licenseImageUrl,

      'idProofType':
          idProofType,

      'idProofNumber':
          idProofNumber,

      'idProofImageUrl':
          idProofImageUrl,

      'createdAt':
          Timestamp.fromDate(
        createdAt,
      ),

      'updatedAt':
          Timestamp.fromDate(
        updatedAt,
      ),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CustomerModel copyWith({
    String? businessId,
    String? branchCode,
    String? phone,
    String? name,
    String? email,
    String? address,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? licenseImageUrl,
    String? idProofType,
    String? idProofNumber,
    String? idProofImageUrl,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id,

      businessId:
          businessId ??
              this.businessId,

      branchCode:
          branchCode ??
              this.branchCode,

      phone:
          phone ??
              this.phone,

      name:
          name ??
              this.name,

      email:
          email ??
              this.email,

      address:
          address ??
              this.address,

      licenseNumber:
          licenseNumber ??
              this.licenseNumber,

      licenseExpiryDate:
          licenseExpiryDate ??
              this.licenseExpiryDate,

      licenseImageUrl:
          licenseImageUrl ??
              this.licenseImageUrl,

      idProofType:
          idProofType ??
              this.idProofType,

      idProofNumber:
          idProofNumber ??
              this.idProofNumber,

      idProofImageUrl:
          idProofImageUrl ??
              this.idProofImageUrl,

      createdAt:
          createdAt,

      updatedAt:
          updatedAt ??
              this.updatedAt,
    );
  }

  // ============================================================
  // DATE HELPER
  // ============================================================

  static DateTime? _dateFromFirestore(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}