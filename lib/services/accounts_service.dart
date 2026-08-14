import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_model.dart';

// ============================================================
// ACCOUNTS SUMMARY
// ============================================================

class AccountsSummary {
  final double totalRent;
  final double totalDeposit;
  final double totalRefundDeposit;

  final List<PaymentModel> payments;

  const AccountsSummary({
    required this.totalRent,
    required this.totalDeposit,
    required this.totalRefundDeposit,
    required this.payments,
  });

  double get totalReceived =>
      totalRent + totalDeposit;

  double get totalRefunded =>
      totalRefundDeposit;
}

// ============================================================
// ACCOUNTS SERVICE
// ============================================================

class AccountsService {
  AccountsService._();

  static final AccountsService instance =
      AccountsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // GET CURRENT USER BUSINESS / BRANCH
  // ==========================================================

  Future<Map<String, String>>
      _getBusinessAndBranch() async {
    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final userSnapshot =
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
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
            .trim()
            .toUpperCase();

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

  // ==========================================================
  // GET ACCOUNTS
  //
  // Firebase-side filtering:
  //
  // businessId
  // branchCode
  // paymentDate
  //
  // No filtering of the full payment list in Flutter.
  // ==========================================================

  Future<AccountsSummary> getAccounts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // ========================================================
    // NORMALIZE DATE RANGE
    // ========================================================

    final start =
        DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // End date is inclusive.
    //
    // Example:
    // Start = 13 Aug
    // End   = 13 Aug
    //
    // Query:
    // >= 13 Aug 00:00
    // < 14 Aug 00:00
    // ========================================================

    final endExclusive =
        DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(
      const Duration(
        days: 1,
      ),
    );

    if (start.isAfter(
      endExclusive,
    )) {
      throw Exception(
        'Start date cannot be after end date.',
      );
    }

    // ========================================================
    // GET BUSINESS / BRANCH
    // ========================================================

    final businessBranch =
        await _getBusinessAndBranch();

    final businessId =
        businessBranch['businessId']!;

    final branchCode =
        businessBranch['branchCode']!;

    // ========================================================
    // FIRESTORE QUERY
    //
    // Collection group allows us to query:
    //
    // bookings/{bookingId}/payments/{paymentId}
    //
    // directly.
    // ========================================================

    Query<Map<String, dynamic>> query =
        _firestore
            .collectionGroup(
              'payments',
            )
            .where(
              'businessId',
              isEqualTo:
                  businessId,
            )
            .where(
              'branchCode',
              isEqualTo:
                  branchCode,
            )
            .where(
              'paymentDate',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(
                start,
              ),
            )
            .where(
              'paymentDate',
              isLessThan:
                  Timestamp.fromDate(
                endExclusive,
              ),
            )
            .orderBy(
              'paymentDate',
              descending: true,
            );

    // ========================================================
    // FIRESTORE READ
    // ========================================================

    final snapshot =
        await query.get();

    // ========================================================
    // CONVERT PAYMENTS
    // ========================================================

    final payments =
        snapshot.docs
            .map(
              (doc) =>
                  PaymentModel.fromFirestore(
                doc,
              ),
            )
            .toList();

    // ========================================================
    // CALCULATE TOTALS
    //
    // These are calculated from the already Firebase-filtered
    // payment documents.
    // ========================================================

    double totalRent = 0.0;

    double totalDeposit = 0.0;

    double totalRefundDeposit = 0.0;

    for (final payment
        in payments) {
      switch (payment.type) {
        case PaymentType.rent:
          totalRent +=
              payment.amount;
          break;

        case PaymentType.deposit:
          totalDeposit +=
              payment.amount;
          break;

        case PaymentType.refundDeposit:
          totalRefundDeposit +=
              payment.amount;
          break;
      }
    }

    // ========================================================
    // RETURN SUMMARY
    // ========================================================

    return AccountsSummary(
      totalRent:
          totalRent,

      totalDeposit:
          totalDeposit,

      totalRefundDeposit:
          totalRefundDeposit,

      payments:
          payments,
    );
  }
}