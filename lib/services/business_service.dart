
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/branch_model.dart';
import '../models/business_model.dart';
import '../models/dashboard_stats_model.dart';

class BusinessService {
  BusinessService._();

  static final BusinessService instance =
      BusinessService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CREATE BUSINESS + BRANCH
  //
  // Architecture:
  //
  // users/{uid}
  // businesses/{businessId}
  // branches/{branchId}
  // branchCodes/{branchCode}
  // dashboardStats/{branchCode}
  //
  // Everything important is created atomically.
  // ============================================================

  Future<void> createBusiness({
    required String businessName,
    required String legalName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String branchName,
    required String branchCode,
    required String branchAddress,
    required String branchCity,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to create your business.',
      );
    }

    // ==========================================================
    // NORMALIZE INPUT
    // ==========================================================

    final normalizedBusinessName =
        businessName.trim();

    final normalizedLegalName =
        legalName.trim();

    final normalizedPhone =
        phone.trim();

    final normalizedEmail =
        email.trim().toLowerCase();

    final normalizedAddress =
        address.trim();

    final normalizedCity =
        city.trim();

    final normalizedState =
        state.trim();

    final normalizedBranchName =
        branchName.trim();

    final normalizedBranchCode =
        branchCode.trim().toUpperCase();

    final normalizedBranchAddress =
        branchAddress.trim();

    final normalizedBranchCity =
        branchCity.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (normalizedBusinessName.isEmpty) {
      throw Exception(
        'Business name is required.',
      );
    }

    if (normalizedLegalName.isEmpty) {
      throw Exception(
        'Legal business name is required.',
      );
    }

    if (normalizedPhone.isEmpty) {
      throw Exception(
        'Business phone is required.',
      );
    }

    if (normalizedEmail.isEmpty) {
      throw Exception(
        'Business email is required.',
      );
    }

    if (normalizedAddress.isEmpty) {
      throw Exception(
        'Business address is required.',
      );
    }

    if (normalizedCity.isEmpty) {
      throw Exception(
        'Business city is required.',
      );
    }

    if (normalizedState.isEmpty) {
      throw Exception(
        'Business state is required.',
      );
    }

    if (normalizedBranchName.isEmpty) {
      throw Exception(
        'Branch name is required.',
      );
    }

    if (normalizedBranchCode.isEmpty) {
      throw Exception(
        'Branch code is required.',
      );
    }

    if (normalizedBranchAddress.isEmpty) {
      throw Exception(
        'Branch address is required.',
      );
    }

    if (normalizedBranchCity.isEmpty) {
      throw Exception(
        'Branch city is required.',
      );
    }

    // ==========================================================
    // BRANCH CODE VALIDATION
    // ==========================================================

    if (normalizedBranchCode.length < 3) {
      throw Exception(
        'Branch code must contain at least 3 characters.',
      );
    }

    if (normalizedBranchCode.length > 15) {
      throw Exception(
        'Branch code cannot contain more than 15 characters.',
      );
    }

    if (!RegExp(
      r'^[A-Z0-9_-]+$',
    ).hasMatch(normalizedBranchCode)) {
      throw Exception(
        'Branch code can contain only letters, numbers, _ and -.',
      );
    }

    // ==========================================================
    // REFERENCES
    // ==========================================================

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final branchCodeRef = _firestore
        .collection('branchCodes')
        .doc(normalizedBranchCode);

    final businessRef = _firestore
        .collection('businesses')
        .doc();

    final branchRef = _firestore
        .collection('branches')
        .doc();

    final dashboardStatsRef = _firestore
        .collection('dashboardStats')
        .doc(normalizedBranchCode);

    // ==========================================================
    // TIMESTAMP
    // ==========================================================

    final now = DateTime.now();

    // ==========================================================
    // MODELS
    // ==========================================================

    final business = BusinessModel(
      id: businessRef.id,

      ownerId: user.uid,

      name:
          normalizedBusinessName,

      legalName:
          normalizedLegalName,

      phone:
          normalizedPhone,

      email:
          normalizedEmail,

      address:
          normalizedAddress,

      city:
          normalizedCity,

      state:
          normalizedState,

      country: 'India',

      branchId:
          branchRef.id,

      branchCode:
          normalizedBranchCode,

      logoUrl: null,

      isActive: true,

      createdAt:
          now,

      updatedAt:
          now,
    );

    final branch = BranchModel(
      id: branchRef.id,

      businessId:
          businessRef.id,

      ownerId:
          user.uid,

      branchCode:
          normalizedBranchCode,

      name:
          normalizedBranchName,

      phone:
          normalizedPhone,

      email:
          normalizedEmail,

      address:
          normalizedBranchAddress,

      city:
          normalizedBranchCity,

      state:
          normalizedState,

      country: 'India',

      isActive: true,

      createdAt:
          now,

      updatedAt:
          now,
    );

    final dashboardStats =
        DashboardStatsModel.empty(
      normalizedBranchCode,
    );

    // ==========================================================
    // TRANSACTION
    //
    // IMPORTANT:
    //
    // All READS happen before WRITES.
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ USER
        // --------------------------------------------------------

        final userSnapshot =
            await transaction.get(
          userRef,
        );

        if (!userSnapshot.exists) {
          throw Exception(
            'Your account profile could not be found.',
          );
        }

        final userData =
            userSnapshot.data();

        if (userData == null) {
          throw Exception(
            'Your account profile is empty.',
          );
        }

        // --------------------------------------------------------
        // CHECK EXISTING BUSINESS
        //
        // ONE USER = ONE BUSINESS
        // --------------------------------------------------------

        final existingBusinessId =
            userData['businessId'];

        if (existingBusinessId != null &&
            existingBusinessId
                .toString()
                .isNotEmpty) {
          throw Exception(
            'You already have a business.',
          );
        }

        // --------------------------------------------------------
        // READ BRANCH CODE
        //
        // Globally unique.
        // --------------------------------------------------------

        final branchCodeSnapshot =
            await transaction.get(
          branchCodeRef,
        );

        if (branchCodeSnapshot.exists) {
          throw Exception(
            'This branch code is already in use.',
          );
        }

        // --------------------------------------------------------
        // READ DASHBOARD STATS
        //
        // Normally this should not exist during first setup.
        // We check it so we never accidentally overwrite
        // an existing branch's statistics.
        // --------------------------------------------------------

        final statsSnapshot =
            await transaction.get(
          dashboardStatsRef,
        );

        if (statsSnapshot.exists) {
          throw Exception(
            'This branch code is already associated with a rental operation.',
          );
        }

        // ========================================================
        // WRITES START HERE
        // ========================================================

        // --------------------------------------------------------
        // BUSINESS
        // --------------------------------------------------------

        transaction.set(
          businessRef,
          business.toFirestore(),
        );

        // --------------------------------------------------------
        // BRANCH
        // --------------------------------------------------------

        transaction.set(
          branchRef,
          branch.toFirestore(),
        );

        // --------------------------------------------------------
        // BRANCH CODE RESERVATION
        // --------------------------------------------------------

        transaction.set(
          branchCodeRef,
          {
            'branchId':
                branchRef.id,

            'businessId':
                businessRef.id,

            'ownerId':
                user.uid,

            'branchCode':
                normalizedBranchCode,

            'createdAt':
                Timestamp.fromDate(
              now,
            ),
          },
        );

        // --------------------------------------------------------
        // INITIAL DASHBOARD STATS
        // --------------------------------------------------------

        transaction.set(
          dashboardStatsRef,
          dashboardStats.toFirestore(),
        );

        // --------------------------------------------------------
        // UPDATE USER
        // --------------------------------------------------------

        transaction.update(
          userRef,
          {
            'businessId':
                businessRef.id,

            'branchId':
                branchRef.id,

            'branchCode':
                normalizedBranchCode,

            'role':
                'owner',

            'updatedAt':
                Timestamp.fromDate(
              now,
            ),
          },
        );
      },
    );
  }

  // ============================================================
  // GET CURRENT USER PROFILE
  //
  // 1 READ
  //
  // Useful when we already need the user context.
  // ============================================================

  Future<
      Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // ============================================================
  // GET CURRENT BUSINESS
  //
  // 2 READS:
  //
  // users/{uid}
  // businesses/{businessId}
  //
  // This is okay when the actual business document is required.
  // ============================================================

  Future<BusinessModel?>
      getCurrentBusiness() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final userSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userSnapshot.exists) {
      return null;
    }

    final userData =
        userSnapshot.data();

    if (userData == null) {
      return null;
    }

    final businessId =
        userData['businessId'];

    if (businessId == null ||
        businessId
            .toString()
            .isEmpty) {
      return null;
    }

    final businessSnapshot =
        await _firestore
            .collection('businesses')
            .doc(
              businessId.toString(),
            )
            .get();

    if (!businessSnapshot.exists) {
      return null;
    }

    return BusinessModel.fromFirestore(
      businessSnapshot,
    );
  }

  // ============================================================
  // GET CURRENT BRANCH
  //
  // 2 READS:
  //
  // users/{uid}
  // branches/{branchId}
  // ============================================================

  Future<BranchModel?>
      getCurrentBranch() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final userSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userSnapshot.exists) {
      return null;
    }

    final userData =
        userSnapshot.data();

    if (userData == null) {
      return null;
    }

    final branchId =
        userData['branchId'];

    if (branchId == null ||
        branchId
            .toString()
            .isEmpty) {
      return null;
    }

    final branchSnapshot =
        await _firestore
            .collection('branches')
            .doc(
              branchId.toString(),
            )
            .get();

    if (!branchSnapshot.exists) {
      return null;
    }

    return BranchModel.fromFirestore(
      branchSnapshot,
    );
  }

  // ============================================================
  // GET CURRENT BUSINESS + BRANCH
  //
  // This is more efficient than calling:
  //
  // getCurrentBusiness()
  // +
  // getCurrentBranch()
  //
  // because that would potentially perform 4 reads.
  //
  // Here:
  //
  // 1 read → users/{uid}
  // 1 read → business
  // 1 read → branch
  //
  // TOTAL = 3 READS
  // ============================================================

  Future<
      ({
        BusinessModel? business,
        BranchModel? branch,
      })> getCurrentBusinessAndBranch() async {
    final user = _auth.currentUser;

    if (user == null) {
      return (
        business: null,
        branch: null,
      );
    }

    // ----------------------------------------------------------
    // USER
    // ----------------------------------------------------------

    final userSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userSnapshot.exists) {
      return (
        business: null,
        branch: null,
      );
    }

    final userData =
        userSnapshot.data();

    if (userData == null) {
      return (
        business: null,
        branch: null,
      );
    }

    final businessId =
        userData['businessId']
            ?.toString();

    final branchId =
        userData['branchId']
            ?.toString();

    if (businessId == null ||
        businessId.isEmpty ||
        branchId == null ||
        branchId.isEmpty) {
      return (
        business: null,
        branch: null,
      );
    }

    // ----------------------------------------------------------
    // BUSINESS + BRANCH
    //
    // Firestore has no normal multi-document get,
    // so these are two independent document reads.
    // ----------------------------------------------------------

    final results =
        await Future.wait([
      _firestore
          .collection('businesses')
          .doc(businessId)
          .get(),

      _firestore
          .collection('branches')
          .doc(branchId)
          .get(),
    ]);

    final businessSnapshot =
        results[0]
            as DocumentSnapshot<
                Map<String, dynamic>>;

    final branchSnapshot =
        results[1]
            as DocumentSnapshot<
                Map<String, dynamic>>;

    final business =
        businessSnapshot.exists
            ? BusinessModel.fromFirestore(
                businessSnapshot,
              )
            : null;

    final branch =
        branchSnapshot.exists
            ? BranchModel.fromFirestore(
                branchSnapshot,
              )
            : null;

    return (
      business: business,
      branch: branch,
    );
  }

  // ============================================================
  // GET CURRENT BRANCH CODE
  //
  // 1 READ
  //
  // This is preferred when we only need the branch code.
  // ============================================================

  Future<String?> getCurrentBranchCode() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data();

    return data?['branchCode']
        ?.toString();
  }

  // ============================================================
  // CHECK WHETHER BUSINESS SETUP IS COMPLETE
  //
  // 1 READ
  //
  // Does NOT read the business or branch.
  // ============================================================

  Future<bool> isBusinessSetupComplete() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final data =
        snapshot.data();

    if (data == null) {
      return false;
    }

    final businessId =
        data['businessId']
            ?.toString();

    final branchId =
        data['branchId']
            ?.toString();

    final branchCode =
        data['branchCode']
            ?.toString();

    return businessId != null &&
        businessId.isNotEmpty &&
        branchId != null &&
        branchId.isNotEmpty &&
        branchCode != null &&
        branchCode.isNotEmpty;
  }

  // ============================================================
  // GET BUSINESS BY ID
  //
  // 1 READ
  //
  // Useful when businessId is already available.
  // ============================================================

  Future<BusinessModel?>
      getBusinessById(
    String businessId,
  ) async {
    final normalizedId =
        businessId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('businesses')
            .doc(normalizedId)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return BusinessModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // GET BRANCH BY ID
  //
  // 1 READ
  // ============================================================

  Future<BranchModel?>
      getBranchById(
    String branchId,
  ) async {
    final normalizedId =
        branchId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('branches')
            .doc(normalizedId)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return BranchModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // CHECK BRANCH CODE AVAILABILITY
  //
  // 1 READ
  //
  // Useful before submitting the setup form.
  // The transaction still performs the authoritative check.
  // ============================================================

  Future<bool> isBranchCodeAvailable(
    String branchCode,
  ) async {
    final normalizedCode =
        branchCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return false;
    }

    final snapshot =
        await _firestore
            .collection('branchCodes')
            .doc(normalizedCode)
            .get();

    return !snapshot.exists;
  }
}

