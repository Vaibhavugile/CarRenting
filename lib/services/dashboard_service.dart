import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_stats_model.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance =
      DashboardService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET DASHBOARD STATS
  //
  // ONE READ ONLY
  // ============================================================

  Future<DashboardStatsModel>
      getStats(String branchCode) async {
    final normalizedCode =
        branchCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Invalid branch code.',
      );
    }

    final snapshot = await _firestore
        .collection('dashboardStats')
        .doc(normalizedCode)
        .get();

    if (!snapshot.exists) {
      return DashboardStatsModel.empty(
        normalizedCode,
      );
    }

    return DashboardStatsModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // CREATE INITIAL STATS
  //
  // Called once after business creation.
  // ============================================================

  Future<void> createInitialStats({
    required String branchCode,
  }) async {
    final normalizedCode =
        branchCode.trim().toUpperCase();

    final ref = _firestore
        .collection('dashboardStats')
        .doc(normalizedCode);

    final snapshot =
        await ref.get();

    if (snapshot.exists) {
      return;
    }

    final stats =
        DashboardStatsModel.empty(
      normalizedCode,
    );

    await ref.set(
      stats.toFirestore(),
    );
  }
}