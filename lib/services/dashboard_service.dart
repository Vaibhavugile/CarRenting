import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_stats_model.dart';
import '../models/payment_model.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance =
      DashboardService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // BOOKING COUNT HELPER
  //
  // Runs ONE Firestore count query and prints:
  // - which query is running
  // - result count
  // - exact Firestore error if an index is missing
  // ============================================================

  Future<int> _getBookingCount({
    required String label,
    required Query<Map<String, dynamic>> query,
  }) async {
    debugPrint('');
    debugPrint(
      '============================================================',
    );
    debugPrint(
      'DASHBOARD QUERY START: $label',
    );
    debugPrint(
      '============================================================',
    );

    try {
      final snapshot =
          await query.count().get();

      final count =
          snapshot.count ?? 0;

      debugPrint(
        '------------------------------------------------------------',
      );
      debugPrint(
        'DASHBOARD QUERY SUCCESS: $label',
      );
      debugPrint(
        'COUNT: $count',
      );
      debugPrint(
        '------------------------------------------------------------',
      );

      return count;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );
      debugPrint(
        'DASHBOARD QUERY FAILED: $label',
      );
      debugPrint(
        'ERROR:',
      );
      debugPrint(
        e.toString(),
      );
      debugPrint(
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // PAYMENT TOTAL HELPER
  //
  // Runs ONE Firestore query for today's payments.
  //
  // Firebase filters:
  // - businessId
  // - branchCode
  // - paymentDate
  //
  // Then we calculate:
  // - rent
  // - deposit
  //
  // Refund Deposit is intentionally ignored.
  // ============================================================

  Future<Map<String, double>>
      _getTodayPaymentTotals({
    required String businessId,
    required String branchCode,
    required Timestamp todayStart,
    required Timestamp tomorrowStart,
  }) async {
    debugPrint('');
    debugPrint(
      '============================================================',
    );
    debugPrint(
      'DASHBOARD PAYMENT QUERY START',
    );
    debugPrint(
      '============================================================',
    );

    try {
      final snapshot =
          await _firestore
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
                    todayStart,
              )
              .where(
                'paymentDate',
                isLessThan:
                    tomorrowStart,
              )
              .get();

      double todayRent = 0.0;

      double todayDeposit = 0.0;

      double todayRefundDeposit = 0.0;

      for (final doc
          in snapshot.docs) {
        final payment =
            PaymentModel.fromFirestore(
          doc,
        );

        switch (payment.type) {
          case PaymentType.rent:
            todayRent +=
                payment.amount;
            break;

          case PaymentType.deposit:
            todayDeposit +=
                payment.amount;
            break;

          case PaymentType.refundDeposit:
            todayRefundDeposit +=
                payment.amount;
            break;
        }
      }

      debugPrint(
        '------------------------------------------------------------',
      );
      debugPrint(
        'DASHBOARD PAYMENT QUERY SUCCESS',
      );
      debugPrint(
        'PAYMENTS FOUND: ${snapshot.docs.length}',
      );
      debugPrint(
        'TODAY RENT: ₹$todayRent',
      );
      debugPrint(
        'TODAY DEPOSIT: ₹$todayDeposit',
      );
      debugPrint(
        'TODAY REFUND DEPOSIT: ₹$todayRefundDeposit',
      );
      debugPrint(
        '------------------------------------------------------------',
      );

      return {
        'todayRent':
            todayRent,
        'todayDeposit':
            todayDeposit,
      };
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );
      debugPrint(
        'DASHBOARD PAYMENT QUERY FAILED',
      );
      debugPrint(
        'ERROR:',
      );
      debugPrint(
        e.toString(),
      );
      debugPrint(
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // GET DASHBOARD STATS
  //
  // Stored stats:
  // - vehicles
  // - revenue
  // - payments
  // - customers
  //
  // Live booking stats:
  // - today's created
  // - today's pickup
  // - today's return
  //
  // Live payment stats:
  // - today's rent
  // - today's deposit
  // ============================================================

  Future<DashboardStatsModel> getStats(
    String branchCode,
  ) async {
    debugPrint('');
    debugPrint(
      '============================================================',
    );
    debugPrint(
      'DASHBOARD: GET STATS STARTED',
    );
    debugPrint(
      '============================================================',
    );

    // ==========================================================
    // NORMALIZE BRANCH
    // ==========================================================

    final normalizedCode =
        branchCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Invalid branch code.',
      );
    }

    debugPrint(
      'Dashboard branch: $normalizedCode',
    );

    // ==========================================================
    // CURRENT USER
    // ==========================================================

    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    debugPrint(
      'Dashboard Firebase UID: ${firebaseUser.uid}',
    );

    // ==========================================================
    // GET USER
    // ==========================================================

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

    final userData =
        userSnapshot.data() ?? {};

    final businessId =
        userData['businessId']
            ?.toString()
            .trim();

    final userBranchCode =
        userData['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (businessId == null ||
        businessId.isEmpty) {
      throw Exception(
        'No business is assigned to your account.',
      );
    }

    if (userBranchCode == null ||
        userBranchCode.isEmpty) {
      throw Exception(
        'No branch is assigned to your account.',
      );
    }

    debugPrint(
      'Dashboard businessId: $businessId',
    );

    debugPrint(
      'Dashboard user branchCode: $userBranchCode',
    );

    // ==========================================================
    // EFFECTIVE BRANCH
    // ==========================================================

    final effectiveBranchCode =
        normalizedCode;

    // ==========================================================
    // TODAY RANGE
    // ==========================================================

    final now =
        DateTime.now();

    final todayStart =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrowStart =
        todayStart.add(
      const Duration(
        days: 1,
      ),
    );

    final todayStartTimestamp =
        Timestamp.fromDate(
      todayStart,
    );

    final tomorrowStartTimestamp =
        Timestamp.fromDate(
      tomorrowStart,
    );

    debugPrint(
      'Dashboard today start: $todayStart',
    );

    debugPrint(
      'Dashboard tomorrow start: $tomorrowStart',
    );

    // ==========================================================
    // EXISTING STORED DASHBOARD STATS
    // ==========================================================

    debugPrint(
      'Loading stored dashboard stats...',
    );

    final statsSnapshot =
        await _firestore
            .collection('dashboardStats')
            .doc(effectiveBranchCode)
            .get();

    DashboardStatsModel storedStats;

    if (statsSnapshot.exists) {
      storedStats =
          DashboardStatsModel.fromFirestore(
        statsSnapshot,
      );

      debugPrint(
        'Stored dashboard stats found.',
      );
    } else {
      storedStats =
          DashboardStatsModel.empty(
        effectiveBranchCode,
      );

      debugPrint(
        'No stored dashboard stats found. Using empty stats.',
      );
    }

    // ==========================================================
    // BASE BOOKINGS COLLECTION
    // ==========================================================

    final bookings =
        _firestore.collection('bookings');

    // ==========================================================
    // 1. TODAY CREATED
    // ==========================================================

    final todayCreatedBookings =
        await _getBookingCount(
      label:
          'CREATED TODAY',
      query: bookings
          .where(
            'businessId',
            isEqualTo:
                businessId,
          )
          .where(
            'branchCode',
            isEqualTo:
                effectiveBranchCode,
          )
          .where(
            'createdAt',
            isGreaterThanOrEqualTo:
                todayStartTimestamp,
          )
          .where(
            'createdAt',
            isLessThan:
                tomorrowStartTimestamp,
          ),
    );

    // ==========================================================
    // 2. TODAY PICKUP
    //
    // NO STATUS FILTER.
    // ==========================================================

    final todayPickupBookings =
        await _getBookingCount(
      label:
          'PICKUP TODAY',
      query: bookings
          .where(
            'businessId',
            isEqualTo:
                businessId,
          )
          .where(
            'branchCode',
            isEqualTo:
                effectiveBranchCode,
          )
          .where(
            'pickupDateTime',
            isGreaterThanOrEqualTo:
                todayStartTimestamp,
          )
          .where(
            'pickupDateTime',
            isLessThan:
                tomorrowStartTimestamp,
          ),
    );

    // ==========================================================
    // 3. TODAY RETURN
    //
    // NO STATUS FILTER.
    // ==========================================================

    final todayReturnBookings =
        await _getBookingCount(
      label:
          'RETURN TODAY',
      query: bookings
          .where(
            'businessId',
            isEqualTo:
                businessId,
          )
          .where(
            'branchCode',
            isEqualTo:
                effectiveBranchCode,
          )
          .where(
            'returnDateTime',
            isGreaterThanOrEqualTo:
                todayStartTimestamp,
          )
          .where(
            'returnDateTime',
            isLessThan:
                tomorrowStartTimestamp,
          ),
    );

    // ==========================================================
    // 4. TODAY PAYMENT TOTALS
    //
    // Firebase filters the payment documents.
    //
    // RENT:
    //   included in todayRent
    //
    // DEPOSIT:
    //   included in todayDeposit
    //
    // REFUND DEPOSIT:
    //   NOT included in either.
    // ==========================================================

    final todayPaymentTotals =
        await _getTodayPaymentTotals(
      businessId:
          businessId,
      branchCode:
          effectiveBranchCode,
      todayStart:
          todayStartTimestamp,
      tomorrowStart:
          tomorrowStartTimestamp,
    );

    final todayRent =
        todayPaymentTotals[
                'todayRent'] ??
            0.0;

    final todayDeposit =
        todayPaymentTotals[
                'todayDeposit'] ??
            0.0;

    // ==========================================================
    // TODAY REVENUE
    //
    // For dashboard revenue:
    //
    // Rent + Deposit
    //
    // Refund Deposit is excluded.
    // ==========================================================

    final todayPaymentRevenue =
        todayRent +
            todayDeposit;

    // ==========================================================
    // PRINT FINAL COUNTS
    // ==========================================================

    debugPrint('');
    debugPrint(
      '============================================================',
    );
    debugPrint(
      'DASHBOARD FINAL VALUES',
    );
    debugPrint(
      'Created Today : $todayCreatedBookings',
    );
    debugPrint(
      'Pickup Today  : $todayPickupBookings',
    );
    debugPrint(
      'Return Today  : $todayReturnBookings',
    );
    debugPrint(
      'Rent Today    : ₹$todayRent',
    );
    debugPrint(
      'Deposit Today : ₹$todayDeposit',
    );
    debugPrint(
      'Revenue Today : ₹$todayPaymentRevenue',
    );
    debugPrint(
      '============================================================',
    );

    // ==========================================================
    // RETURN DASHBOARD
    // ==========================================================

    return storedStats.copyWith(
      branchCode:
          effectiveBranchCode,

      // --------------------------------------------------------
      // BOOKING STATS
      // --------------------------------------------------------

      todayCreatedBookings:
          todayCreatedBookings,

      todayPickupBookings:
          todayPickupBookings,

      todayReturnBookings:
          todayReturnBookings,

      // --------------------------------------------------------
      // PAYMENT / REVENUE STATS
      // --------------------------------------------------------

      todayRent:
          todayRent,

      todayDeposit:
          todayDeposit,

      todayRevenue:
          todayPaymentRevenue,

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      updatedAt:
          DateTime.now(),
    );
  }

  // ============================================================
  // CREATE INITIAL STATS
  //
  // Called once after business / branch creation.
  // ============================================================

  Future<void> createInitialStats({
    required String branchCode,
  }) async {
    final normalizedCode =
        branchCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Invalid branch code.',
      );
    }

    final ref =
        _firestore
            .collection('dashboardStats')
            .doc(normalizedCode);

    final snapshot =
        await ref.get();

    if (snapshot.exists) {
      debugPrint(
        'Dashboard stats already exist for $normalizedCode',
      );

      return;
    }

    final stats =
        DashboardStatsModel.empty(
      normalizedCode,
    );

    await ref.set(
      stats.toFirestore(),
    );

    debugPrint(
      'Dashboard stats created for $normalizedCode',
    );
  }
}