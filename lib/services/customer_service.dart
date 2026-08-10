import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:car_rental/models/customer_model.dart';

class CustomerService {
CustomerService._();

static final CustomerService instance =
CustomerService._();

final FirebaseFirestore _firestore =
FirebaseFirestore.instance;

final FirebaseAuth _auth =
FirebaseAuth.instance;

CollectionReference<Map<String, dynamic>>
get _customers =>
_firestore.collection('customers');

User? get currentUser =>
_auth.currentUser;

// ============================================================
// NORMALIZE PHONE
// ============================================================

String normalizePhone(
String phone,
) {
return phone
.replaceAll(
RegExp(r'[\s-()]'),
'',
)
.trim();
}

// ============================================================
// GET CURRENT BUSINESS / BRANCH
//
// IMPORTANT:
// Replace these two getters with the same user-model logic
// you already use inside BookingService if your project
// stores businessId / branchCode somewhere else.
// ============================================================

Future<Map<String, String>> _getBusinessContext() async {
final user =
currentUser;


if (user == null) {
  throw Exception(
    'You must be logged in.',
  );
}

final userSnapshot =
    await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

if (!userSnapshot.exists) {
  throw Exception(
    'User profile not found.',
  );
}

final data =
    userSnapshot.data() ?? {};

final businessId =
    data['businessId']
        ?.toString()
        .trim();

final branchCode =
    data['branchCode']
        ?.toString()
        .trim();

if (businessId == null ||
    businessId.isEmpty) {
  throw Exception(
    'No business is assigned to your account.',
  );
}

if (branchCode == null ||
    branchCode.isEmpty) {
  throw Exception(
    'No branch is assigned to your account.',
  );
}

return {
  'businessId':
      businessId,
  'branchCode':
      branchCode,
};


}

// ============================================================
// FIND CUSTOMER BY PHONE
//
// One customer should exist for a phone number within the
// same business.
// ============================================================

Future<CustomerModel?> findByPhone(
String phone,
) async {
final normalizedPhone =
normalizePhone(
phone,
);


if (normalizedPhone.isEmpty) {
  return null;
}

final context =
    await _getBusinessContext();

final snapshot =
    await _customers
        .where(
          'businessId',
          isEqualTo:
              context['businessId'],
        )
        .where(
          'phone',
          isEqualTo:
              normalizedPhone,
        )
        .limit(1)
        .get();

if (snapshot.docs.isEmpty) {
  return null;
}

return CustomerModel.fromFirestore(
  snapshot.docs.first,
);


}

// ============================================================
// GET CUSTOMER BY ID
// ============================================================

Future<CustomerModel?> getCustomer(
String customerId,
) async {
if (customerId.trim().isEmpty) {
return null;
}

final context =
    await _getBusinessContext();

final snapshot =
    await _customers
        .doc(
          customerId,
        )
        .get();

if (!snapshot.exists) {
  return null;
}

final customer =
    CustomerModel.fromFirestore(
  snapshot,
);

if (customer.businessId !=
        context['businessId'] ||
    customer.branchCode !=
        context['branchCode']) {
  throw Exception(
    'This customer does not belong to your branch.',
  );
}

return customer;


}

// ============================================================
// CREATE CUSTOMER
//
// Before creating:
// 1. Normalize phone
// 2. Search existing customer
// 3. Return existing customer if found
// 4. Otherwise create a new customer
// ============================================================

Future<CustomerModel> createCustomer({
required String name,
required String phone,
String? email,
String? address,
String? licenseNumber,
DateTime? licenseExpiryDate,
String? licenseImageUrl,
String? idProofType,
String? idProofNumber,
String? idProofImageUrl,
}) async {
final user =
currentUser;


if (user == null) {
  throw Exception(
    'You must be logged in.',
  );
}

final cleanName =
    name.trim();

final normalizedPhone =
    normalizePhone(
  phone,
);

if (cleanName.isEmpty) {
  throw Exception(
    'Customer name is required.',
  );
}

if (normalizedPhone.isEmpty) {
  throw Exception(
    'Customer phone number is required.',
  );
}

final context =
    await _getBusinessContext();

// ----------------------------------------------------------
// CHECK EXISTING CUSTOMER
// ----------------------------------------------------------

final existingSnapshot =
    await _customers
        .where(
          'businessId',
          isEqualTo:
              context['businessId'],
        )
        .where(
          'phone',
          isEqualTo:
              normalizedPhone,
        )
        .limit(1)
        .get();

if (existingSnapshot.docs.isNotEmpty) {
  return CustomerModel.fromFirestore(
    existingSnapshot.docs.first,
  );
}

// ----------------------------------------------------------
// CREATE
// ----------------------------------------------------------

final customerRef =
    _customers.doc();

final now =
    DateTime.now();

final customer =
    CustomerModel(
  id:
      customerRef.id,

  businessId:
      context['businessId']!,

  branchCode:
      context['branchCode']!,

  phone:
      normalizedPhone,

  name:
      cleanName,

  email:
      email?.trim().isEmpty == true
          ? null
          : email?.trim(),

  address:
      address?.trim().isEmpty == true
          ? null
          : address?.trim(),

  licenseNumber:
      licenseNumber?.trim().isEmpty == true
          ? null
          : licenseNumber?.trim(),

  licenseExpiryDate:
      licenseExpiryDate,

  licenseImageUrl:
      licenseImageUrl,

  idProofType:
      idProofType?.trim().isEmpty == true
          ? null
          : idProofType?.trim(),

  idProofNumber:
      idProofNumber?.trim().isEmpty == true
          ? null
          : idProofNumber?.trim(),

  idProofImageUrl:
      idProofImageUrl,

  createdAt:
      now,

  updatedAt:
      now,
);

await customerRef.set(
  customer.toFirestore(),
);

return customer;


}

// ============================================================
// UPDATE CUSTOMER
// ============================================================

Future<CustomerModel> updateCustomer({
required String customerId,
String? name,
String? phone,
String? email,
String? address,
String? licenseNumber,
DateTime? licenseExpiryDate,
String? licenseImageUrl,
String? idProofType,
String? idProofNumber,
String? idProofImageUrl,
}) async {
final user =
currentUser;


if (user == null) {
  throw Exception(
    'You must be logged in.',
  );
}

final existing =
    await getCustomer(
  customerId,
);

if (existing == null) {
  throw Exception(
    'Customer not found.',
  );
}

final context =
    await _getBusinessContext();

final normalizedPhone =
    phone == null
        ? existing.phone
        : normalizePhone(
            phone,
          );

if (normalizedPhone.isEmpty) {
  throw Exception(
    'Customer phone number is required.',
  );
}

// ----------------------------------------------------------
// CHECK PHONE DUPLICATE
// ----------------------------------------------------------

if (normalizedPhone !=
    existing.phone) {
  final duplicateSnapshot =
      await _customers
          .where(
            'businessId',
            isEqualTo:
                context['businessId'],
          )
          .where(
            'phone',
            isEqualTo:
                normalizedPhone,
          )
          .limit(1)
          .get();

  if (duplicateSnapshot.docs.isNotEmpty &&
      duplicateSnapshot.docs.first.id !=
          customerId) {
    throw Exception(
      'Another customer already uses this phone number.',
    );
  }
}

final now =
    DateTime.now();

final updated =
    existing.copyWith(
  name:
      name?.trim().isEmpty == true
          ? existing.name
          : name?.trim(),

  phone:
      normalizedPhone,

  email:
      email?.trim().isEmpty == true
          ? null
          : email?.trim(),

  address:
      address?.trim().isEmpty == true
          ? null
          : address?.trim(),

  licenseNumber:
      licenseNumber?.trim().isEmpty == true
          ? null
          : licenseNumber?.trim(),

  licenseExpiryDate:
      licenseExpiryDate,

  licenseImageUrl:
      licenseImageUrl,

  idProofType:
      idProofType?.trim().isEmpty == true
          ? null
          : idProofType?.trim(),

  idProofNumber:
      idProofNumber?.trim().isEmpty == true
          ? null
          : idProofNumber?.trim(),

  idProofImageUrl:
      idProofImageUrl,

  updatedAt:
      now,
);

await _customers
    .doc(customerId)
    .update(
  {
    ...updated.toFirestore(),
    'updatedAt':
        FieldValue.serverTimestamp(),
  },
);

return updated.copyWith(
  updatedAt:
      now,
);


}

// ============================================================
// SEARCH CUSTOMERS
//
// Used later by CreateBookingScreen.
//
// Searches by:
// - phone
// - name
// ============================================================

Future<List<CustomerModel>> searchCustomers({
String query = '',
int limit = 20,
}) async {
final context =
await _getBusinessContext();


final cleanQuery =
    query.trim();

Query<Map<String, dynamic>> queryRef =
    _customers.where(
  'businessId',
  isEqualTo:
      context['businessId'],
);

if (cleanQuery.isNotEmpty) {
  final normalizedPhone =
      normalizePhone(
    cleanQuery,
  );

  // --------------------------------------------------------
  // Phone search
  // --------------------------------------------------------

  final phoneSnapshot =
      await queryRef
          .where(
            'phone',
            isEqualTo:
                normalizedPhone,
          )
          .limit(limit)
          .get();

  if (phoneSnapshot.docs.isNotEmpty) {
    return phoneSnapshot.docs
        .map(
          CustomerModel.fromFirestore,
        )
        .toList();
  }

  // --------------------------------------------------------
  // Name prefix search
  // --------------------------------------------------------

  final nameSnapshot =
      await queryRef
          .orderBy(
            'name',
          )
          .startAt(
            [cleanQuery],
          )
          .endAt(
            ['$cleanQuery\uf8ff'],
          )
          .limit(limit)
          .get();

  return nameSnapshot.docs
      .map(
        CustomerModel.fromFirestore,
      )
      .toList();
}

// ----------------------------------------------------------
// Recent customers
// ----------------------------------------------------------

final snapshot =
    await queryRef
        .orderBy(
          'updatedAt',
          descending:
              true,
        )
        .limit(limit)
        .get();

return snapshot.docs
    .map(
      CustomerModel.fromFirestore,
    )
    .toList();


}
}
