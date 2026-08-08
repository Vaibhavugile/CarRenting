
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardStatsModel {
  // ============================================================
  // BRANCH
  // ============================================================

  final String branchCode;

  // ============================================================
  // VEHICLE STATISTICS
  // ============================================================

  final int totalVehicles;
  final int availableVehicles;
  final int reservedVehicles;
  final int rentedVehicles;
  final int maintenanceVehicles;

  // ============================================================
  // BOOKING STATISTICS
  // ============================================================

  final int todayBookings;
  final int activeBookings;
  final int upcomingBookings;

  // ============================================================
  // REVENUE
  // ============================================================

  final double todayRevenue;
  final double monthRevenue;

  // ============================================================
  // PAYMENTS
  // ============================================================

  final double pendingPayments;

  // ============================================================
  // CUSTOMERS
  // ============================================================

  final int totalCustomers;

  // ============================================================
  // TIMESTAMP
  // ============================================================

  final DateTime updatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardStatsModel({
    required this.branchCode,

    required this.totalVehicles,
    required this.availableVehicles,
    required this.reservedVehicles,
    required this.rentedVehicles,
    required this.maintenanceVehicles,

    required this.todayBookings,
    required this.activeBookings,
    required this.upcomingBookings,

    required this.todayRevenue,
    required this.monthRevenue,

    required this.pendingPayments,

    required this.totalCustomers,

    required this.updatedAt,
  });

  // ============================================================
  // EMPTY / INITIAL MODEL
  //
  // Used when a new branch is created.
  // ============================================================

  factory DashboardStatsModel.empty(
    String branchCode,
  ) {
    return DashboardStatsModel(
      branchCode:
          branchCode
              .trim()
              .toUpperCase(),

      // --------------------------------------------------------
      // VEHICLES
      // --------------------------------------------------------

      totalVehicles:
          0,

      availableVehicles:
          0,

      reservedVehicles:
          0,

      rentedVehicles:
          0,

      maintenanceVehicles:
          0,

      // --------------------------------------------------------
      // BOOKINGS
      // --------------------------------------------------------

      todayBookings:
          0,

      activeBookings:
          0,

      upcomingBookings:
          0,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      todayRevenue:
          0.0,

      monthRevenue:
          0.0,

      // --------------------------------------------------------
      // PAYMENTS
      // --------------------------------------------------------

      pendingPayments:
          0.0,

      // --------------------------------------------------------
      // CUSTOMERS
      // --------------------------------------------------------

      totalCustomers:
          0,

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      updatedAt:
          DateTime.now(),
    );
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory DashboardStatsModel.fromFirestore(
    DocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? {};

    return DashboardStatsModel(
      // --------------------------------------------------------
      // BRANCH
      // --------------------------------------------------------

      branchCode:
          data['branchCode']
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              doc.id
                  .trim()
                  .toUpperCase(),

      // --------------------------------------------------------
      // VEHICLES
      // --------------------------------------------------------

      totalVehicles:
          _toInt(
        data['totalVehicles'],
      ),

      availableVehicles:
          _toInt(
        data['availableVehicles'],
      ),

      reservedVehicles:
          _toInt(
        data['reservedVehicles'],
      ),

      rentedVehicles:
          _toInt(
        data['rentedVehicles'],
      ),

      maintenanceVehicles:
          _toInt(
        data['maintenanceVehicles'],
      ),

      // --------------------------------------------------------
      // BOOKINGS
      // --------------------------------------------------------

      todayBookings:
          _toInt(
        data['todayBookings'],
      ),

      activeBookings:
          _toInt(
        data['activeBookings'],
      ),

      upcomingBookings:
          _toInt(
        data['upcomingBookings'],
      ),

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      todayRevenue:
          _toDouble(
        data['todayRevenue'],
      ),

      monthRevenue:
          _toDouble(
        data['monthRevenue'],
      ),

      // --------------------------------------------------------
      // PAYMENTS
      // --------------------------------------------------------

      pendingPayments:
          _toDouble(
        data['pendingPayments'],
      ),

      // --------------------------------------------------------
      // CUSTOMERS
      // --------------------------------------------------------

      totalCustomers:
          _toInt(
        data['totalCustomers'],
      ),

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      updatedAt:
          _toDateTime(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      // --------------------------------------------------------
      // BRANCH
      // --------------------------------------------------------

      'branchCode':
          branchCode,

      // --------------------------------------------------------
      // VEHICLES
      // --------------------------------------------------------

      'totalVehicles':
          totalVehicles,

      'availableVehicles':
          availableVehicles,

      'reservedVehicles':
          reservedVehicles,

      'rentedVehicles':
          rentedVehicles,

      'maintenanceVehicles':
          maintenanceVehicles,

      // --------------------------------------------------------
      // BOOKINGS
      // --------------------------------------------------------

      'todayBookings':
          todayBookings,

      'activeBookings':
          activeBookings,

      'upcomingBookings':
          upcomingBookings,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      'todayRevenue':
          todayRevenue,

      'monthRevenue':
          monthRevenue,

      // --------------------------------------------------------
      // PAYMENTS
      // --------------------------------------------------------

      'pendingPayments':
          pendingPayments,

      // --------------------------------------------------------
      // CUSTOMERS
      // --------------------------------------------------------

      'totalCustomers':
          totalCustomers,

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      'updatedAt':
          Timestamp.fromDate(
        updatedAt,
      ),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  DashboardStatsModel copyWith({
    String? branchCode,

    int? totalVehicles,
    int? availableVehicles,
    int? reservedVehicles,
    int? rentedVehicles,
    int? maintenanceVehicles,

    int? todayBookings,
    int? activeBookings,
    int? upcomingBookings,

    double? todayRevenue,
    double? monthRevenue,

    double? pendingPayments,

    int? totalCustomers,

    DateTime? updatedAt,
  }) {
    return DashboardStatsModel(
      branchCode:
          branchCode ??
              this.branchCode,

      // --------------------------------------------------------
      // VEHICLES
      // --------------------------------------------------------

      totalVehicles:
          totalVehicles ??
              this.totalVehicles,

      availableVehicles:
          availableVehicles ??
              this.availableVehicles,

      reservedVehicles:
          reservedVehicles ??
              this.reservedVehicles,

      rentedVehicles:
          rentedVehicles ??
              this.rentedVehicles,

      maintenanceVehicles:
          maintenanceVehicles ??
              this.maintenanceVehicles,

      // --------------------------------------------------------
      // BOOKINGS
      // --------------------------------------------------------

      todayBookings:
          todayBookings ??
              this.todayBookings,

      activeBookings:
          activeBookings ??
              this.activeBookings,

      upcomingBookings:
          upcomingBookings ??
              this.upcomingBookings,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      todayRevenue:
          todayRevenue ??
              this.todayRevenue,

      monthRevenue:
          monthRevenue ??
              this.monthRevenue,

      // --------------------------------------------------------
      // PAYMENTS
      // --------------------------------------------------------

      pendingPayments:
          pendingPayments ??
              this.pendingPayments,

      // --------------------------------------------------------
      // CUSTOMERS
      // --------------------------------------------------------

      totalCustomers:
          totalCustomers ??
              this.totalCustomers,

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      updatedAt:
          updatedAt ??
              this.updatedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _toDouble(
    dynamic value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static DateTime _toDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}

