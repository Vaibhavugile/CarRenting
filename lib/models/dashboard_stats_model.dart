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

  final int todayCreatedBookings;
  final int todayPickupBookings;
  final int todayReturnBookings;

  // ============================================================
  // REVENUE
  // ============================================================

  // Existing revenue values
  final double todayRevenue;
  final double monthRevenue;

  // Today's payment breakdown
  final double todayRent;
  final double todayDeposit;

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

    // VEHICLES
    required this.totalVehicles,
    required this.availableVehicles,
    required this.reservedVehicles,
    required this.rentedVehicles,
    required this.maintenanceVehicles,

    // BOOKINGS
    required this.todayCreatedBookings,
    required this.todayPickupBookings,
    required this.todayReturnBookings,

    // REVENUE
    required this.todayRevenue,
    required this.monthRevenue,
    required this.todayRent,
    required this.todayDeposit,

    // PAYMENTS
    required this.pendingPayments,

    // CUSTOMERS
    required this.totalCustomers,

    // TIMESTAMP
    required this.updatedAt,
  });

  // ============================================================
  // EMPTY / INITIAL MODEL
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

      totalVehicles: 0,

      availableVehicles: 0,

      reservedVehicles: 0,

      rentedVehicles: 0,

      maintenanceVehicles: 0,

      // --------------------------------------------------------
      // BOOKINGS
      // --------------------------------------------------------

      todayCreatedBookings: 0,

      todayPickupBookings: 0,

      todayReturnBookings: 0,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      todayRevenue: 0.0,

      monthRevenue: 0.0,

      todayRent: 0.0,

      todayDeposit: 0.0,

      // --------------------------------------------------------
      // PAYMENTS
      // --------------------------------------------------------

      pendingPayments: 0.0,

      // --------------------------------------------------------
      // CUSTOMERS
      // --------------------------------------------------------

      totalCustomers: 0,

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
    DocumentSnapshot<Map<String, dynamic>> doc,
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

      todayCreatedBookings:
          _toInt(
        data['todayCreatedBookings'],
      ),

      todayPickupBookings:
          _toInt(
        data['todayPickupBookings'],
      ),

      todayReturnBookings:
          _toInt(
        data['todayReturnBookings'],
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
      // TODAY RENT
      //
      // Old dashboard documents may not have this field.
      // Default = 0 so existing documents continue working.
      // --------------------------------------------------------

      todayRent:
          _toDouble(
        data['todayRent'],
      ),

      // --------------------------------------------------------
      // TODAY DEPOSIT
      //
      // Old dashboard documents may not have this field.
      // Default = 0 so existing documents continue working.
      // --------------------------------------------------------

      todayDeposit:
          _toDouble(
        data['todayDeposit'],
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

      'todayCreatedBookings':
          todayCreatedBookings,

      'todayPickupBookings':
          todayPickupBookings,

      'todayReturnBookings':
          todayReturnBookings,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      'todayRevenue':
          todayRevenue,

      'monthRevenue':
          monthRevenue,

      'todayRent':
          todayRent,

      'todayDeposit':
          todayDeposit,

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

    // VEHICLES
    int? totalVehicles,
    int? availableVehicles,
    int? reservedVehicles,
    int? rentedVehicles,
    int? maintenanceVehicles,

    // BOOKINGS
    int? todayCreatedBookings,
    int? todayPickupBookings,
    int? todayReturnBookings,

    // REVENUE
    double? todayRevenue,
    double? monthRevenue,
    double? todayRent,
    double? todayDeposit,

    // PAYMENTS
    double? pendingPayments,

    // CUSTOMERS
    int? totalCustomers,

    // TIMESTAMP
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

      todayCreatedBookings:
          todayCreatedBookings ??
              this.todayCreatedBookings,

      todayPickupBookings:
          todayPickupBookings ??
              this.todayPickupBookings,

      todayReturnBookings:
          todayReturnBookings ??
              this.todayReturnBookings,

      // --------------------------------------------------------
      // REVENUE
      // --------------------------------------------------------

      todayRevenue:
          todayRevenue ??
              this.todayRevenue,

      monthRevenue:
          monthRevenue ??
              this.monthRevenue,

      todayRent:
          todayRent ??
              this.todayRent,

      todayDeposit:
          todayDeposit ??
              this.todayDeposit,

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