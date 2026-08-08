
import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus {
  available,
  reserved,
  rented,
  maintenance,
  inactive,
}

class VehicleModel {
  final String id;

  // ============================================================
  // OWNERSHIP / BRANCH
  // ============================================================

  final String businessId;
  final String branchCode;

  // ============================================================
  // VEHICLE INFORMATION
  // ============================================================

  final String registrationNumber;

  final String make;
  final String model;
  final String variant;

  final String vehicleType;

  final String fuelType;
  final String transmission;

  final int year;

  final String color;

  // ============================================================
  // KM
  // ============================================================

  final int currentKm;

  // ============================================================
  // RENTAL PRICING
  // ============================================================

  final double dailyRate;
  final double weeklyRate;
  final double monthlyRate;

  final double securityDeposit;

  // ============================================================
  // STATUS
  // ============================================================

  final VehicleStatus status;

  final bool isActive;

  // ============================================================
  // MEDIA
  // ============================================================

  final String? imageUrl;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  final DateTime createdAt;
  final DateTime updatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const VehicleModel({
    required this.id,

    required this.businessId,
    required this.branchCode,

    required this.registrationNumber,

    required this.make,
    required this.model,
    required this.variant,

    required this.vehicleType,

    required this.fuelType,
    required this.transmission,

    required this.year,

    required this.color,

    required this.currentKm,

    required this.dailyRate,
    required this.weeklyRate,
    required this.monthlyRate,

    required this.securityDeposit,

    required this.status,

    required this.isActive,

    this.imageUrl,

    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // STATUS → STRING
  // ============================================================

  static String statusToString(
    VehicleStatus status,
  ) {
    switch (status) {
      case VehicleStatus.available:
        return 'available';

      case VehicleStatus.reserved:
        return 'reserved';

      case VehicleStatus.rented:
        return 'rented';

      case VehicleStatus.maintenance:
        return 'maintenance';

      case VehicleStatus.inactive:
        return 'inactive';
    }
  }

  // ============================================================
  // STRING → STATUS
  //
  // PUBLIC because VehicleService uses this when changing
  // vehicle status.
  // ============================================================

  static VehicleStatus statusFromString(
    String? value,
  ) {
    switch (value?.toLowerCase()) {
      case 'reserved':
        return VehicleStatus.reserved;

      case 'rented':
        return VehicleStatus.rented;

      case 'maintenance':
        return VehicleStatus.maintenance;

      case 'inactive':
        return VehicleStatus.inactive;

      case 'available':
      default:
        return VehicleStatus.available;
    }
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory VehicleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? {};

    return VehicleModel(
      id: doc.id,

      // --------------------------------------------------------
      // OWNERSHIP
      // --------------------------------------------------------

      businessId:
          data['businessId']
                  ?.toString() ??
              '',

      branchCode:
          data['branchCode']
                  ?.toString() ??
              '',

      // --------------------------------------------------------
      // VEHICLE
      // --------------------------------------------------------

      registrationNumber:
          data['registrationNumber']
                  ?.toString() ??
              '',

      make:
          data['make']
                  ?.toString() ??
              '',

      model:
          data['model']
                  ?.toString() ??
              '',

      variant:
          data['variant']
                  ?.toString() ??
              '',

      vehicleType:
          data['vehicleType']
                  ?.toString() ??
              'car',

      fuelType:
          data['fuelType']
                  ?.toString() ??
              'petrol',

      transmission:
          data['transmission']
                  ?.toString() ??
              'manual',

      // --------------------------------------------------------
      // YEAR
      // --------------------------------------------------------

      year:
          _toInt(
        data['year'],
      ),

      // --------------------------------------------------------
      // COLOR
      // --------------------------------------------------------

      color:
          data['color']
                  ?.toString() ??
              '',

      // --------------------------------------------------------
      // KM
      // --------------------------------------------------------

      currentKm:
          _toInt(
        data['currentKm'],
      ),

      // --------------------------------------------------------
      // PRICING
      // --------------------------------------------------------

      dailyRate:
          _toDouble(
        data['dailyRate'],
      ),

      weeklyRate:
          _toDouble(
        data['weeklyRate'],
      ),

      monthlyRate:
          _toDouble(
        data['monthlyRate'],
      ),

      securityDeposit:
          _toDouble(
        data['securityDeposit'],
      ),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      status:
          statusFromString(
        data['status']?.toString(),
      ),

      // --------------------------------------------------------
      // ACTIVE
      // --------------------------------------------------------

      isActive:
          data['isActive'] == null
              ? true
              : data['isActive'] == true,

      // --------------------------------------------------------
      // IMAGE
      // --------------------------------------------------------

      imageUrl:
          data['imageUrl']
              ?.toString(),

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      createdAt:
          _toDateTime(
        data['createdAt'],
      ),

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
      // OWNERSHIP
      // --------------------------------------------------------

      'businessId':
          businessId,

      'branchCode':
          branchCode,

      // --------------------------------------------------------
      // VEHICLE
      // --------------------------------------------------------

      'registrationNumber':
          registrationNumber,

      'make':
          make,

      'model':
          model,

      'variant':
          variant,

      'vehicleType':
          vehicleType,

      'fuelType':
          fuelType,

      'transmission':
          transmission,

      'year':
          year,

      'color':
          color,

      // --------------------------------------------------------
      // KM
      // --------------------------------------------------------

      'currentKm':
          currentKm,

      // --------------------------------------------------------
      // PRICING
      // --------------------------------------------------------

      'dailyRate':
          dailyRate,

      'weeklyRate':
          weeklyRate,

      'monthlyRate':
          monthlyRate,

      'securityDeposit':
          securityDeposit,

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'status':
          statusToString(
        status,
      ),

      'isActive':
          isActive,

      // --------------------------------------------------------
      // IMAGE
      // --------------------------------------------------------

      'imageUrl':
          imageUrl,

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

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

  VehicleModel copyWith({
    String? businessId,
    String? branchCode,

    String? registrationNumber,

    String? make,
    String? model,
    String? variant,

    String? vehicleType,

    String? fuelType,
    String? transmission,

    int? year,

    String? color,

    int? currentKm,

    double? dailyRate,
    double? weeklyRate,
    double? monthlyRate,

    double? securityDeposit,

    VehicleStatus? status,

    bool? isActive,

    String? imageUrl,

    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id,

      businessId:
          businessId ??
              this.businessId,

      branchCode:
          branchCode ??
              this.branchCode,

      registrationNumber:
          registrationNumber ??
              this.registrationNumber,

      make:
          make ??
              this.make,

      model:
          model ??
              this.model,

      variant:
          variant ??
              this.variant,

      vehicleType:
          vehicleType ??
              this.vehicleType,

      fuelType:
          fuelType ??
              this.fuelType,

      transmission:
          transmission ??
              this.transmission,

      year:
          year ??
              this.year,

      color:
          color ??
              this.color,

      currentKm:
          currentKm ??
              this.currentKm,

      dailyRate:
          dailyRate ??
              this.dailyRate,

      weeklyRate:
          weeklyRate ??
              this.weeklyRate,

      monthlyRate:
          monthlyRate ??
              this.monthlyRate,

      securityDeposit:
          securityDeposit ??
              this.securityDeposit,

      status:
          status ??
              this.status,

      isActive:
          isActive ??
              this.isActive,

      imageUrl:
          imageUrl ??
              this.imageUrl,

      createdAt:
          createdAt,

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

