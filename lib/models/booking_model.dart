
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// BOOKING STATUS
// ============================================================

enum BookingStatus {
  draft,
  confirmed,
  active,
  completed,
  cancelled,
  noShow,
}

// ============================================================
// PAYMENT STATUS
// ============================================================

enum PaymentStatus {
  unpaid,
  partiallyPaid,
  paid,
  refunded,
}

// ============================================================
// FUEL TYPE / LEVEL
// ============================================================

enum FuelLevel {
  empty,
  quarter,
  half,
  threeQuarter,
  full,
}

// ============================================================
// BOOKING MODEL
// ============================================================

class BookingModel {
  // ==========================================================
  // IDENTITY
  // ==========================================================

  final String id;

  final String businessId;
  final String branchCode;

  final String bookingNumber;

  // ==========================================================
  // CUSTOMER
  // ==========================================================

  final String customerId;

  final String customerName;
  final String customerPhone;

  // ==========================================================
  // VEHICLE
  // ==========================================================

  final String vehicleId;

  final String vehicleRegistrationNumber;

  final String vehicleName;

  // ==========================================================
  // RENTAL PERIOD
  //
  // IMPORTANT:
  // Always use DateTime.
  //
  // This supports:
  // - hourly rentals
  // - same-day rentals
  // - overnight rentals
  // - multi-day rentals
  // - future bookings
  // ==========================================================

  final DateTime pickupDateTime;

  final DateTime returnDateTime;

  // ==========================================================
  // LOCATIONS
  // ==========================================================

  final String pickupLocation;

  final String returnLocation;

  // ==========================================================
  // ODOMETER / FUEL
  // ==========================================================

  final int startingKm;

  final int? endingKm;

  final FuelLevel fuelAtPickup;

  final FuelLevel? fuelAtReturn;

  // ==========================================================
  // PRICING
  // ==========================================================

  final double dailyRate;

  final double? hourlyRate;

  final int rentalDays;

  final int rentalHours;

  final double baseRentalAmount;

  final double securityDeposit;

  final double extraKmCharge;

  final double fuelCharge;

  final double lateReturnCharge;

  final double damageCharge;

  final double otherCharges;

  final double discount;

  final double tax;

  final double totalAmount;

  final double paidAmount;

  final double pendingAmount;

  // ==========================================================
  // BOOKING STATUS
  // ==========================================================

  final BookingStatus status;

  final PaymentStatus paymentStatus;

  // ==========================================================
  // RENTAL AGREEMENT
  // ==========================================================

  final String agreementNumber;

  final bool termsAccepted;

  final String? customerSignatureUrl;

  final String? staffSignatureUrl;

  // ==========================================================
  // DOCUMENTS
  // ==========================================================

  final String? licenseNumber;

  final DateTime? licenseExpiryDate;

  final String? licenseImageUrl;

  final String? idProofType;

  final String? idProofNumber;

  final String? idProofImageUrl;

  // ==========================================================
  // STAFF
  // ==========================================================

  final String createdBy;

  final String? confirmedBy;

  final String? startedBy;

  final String? completedBy;

  final String? cancelledBy;

  // ==========================================================
  // NOTES
  // ==========================================================

  final String? customerNotes;

  final String? internalNotes;

  // ==========================================================
  // TIMESTAMPS
  // ==========================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? confirmedAt;

  final DateTime? startedAt;

  final DateTime? completedAt;

  final DateTime? cancelledAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const BookingModel({
    required this.id,

    required this.businessId,
    required this.branchCode,

    required this.bookingNumber,

    required this.customerId,
    required this.customerName,
    required this.customerPhone,

    required this.vehicleId,
    required this.vehicleRegistrationNumber,
    required this.vehicleName,

    required this.pickupDateTime,
    required this.returnDateTime,

    required this.pickupLocation,
    required this.returnLocation,

    required this.startingKm,
    this.endingKm,

    required this.fuelAtPickup,
    this.fuelAtReturn,

    required this.dailyRate,
    this.hourlyRate,

    required this.rentalDays,
    required this.rentalHours,

    required this.baseRentalAmount,
    required this.securityDeposit,

    required this.extraKmCharge,
    required this.fuelCharge,
    required this.lateReturnCharge,
    required this.damageCharge,
    required this.otherCharges,

    required this.discount,
    required this.tax,

    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,

    required this.status,
    required this.paymentStatus,

    required this.agreementNumber,
    required this.termsAccepted,

    this.customerSignatureUrl,
    this.staffSignatureUrl,

    this.licenseNumber,
    this.licenseExpiryDate,
    this.licenseImageUrl,

    this.idProofType,
    this.idProofNumber,
    this.idProofImageUrl,

    required this.createdBy,

    this.confirmedBy,
    this.startedBy,
    this.completedBy,
    this.cancelledBy,

    this.customerNotes,
    this.internalNotes,

    required this.createdAt,
    required this.updatedAt,

    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  // ==========================================================
  // STATUS FROM STRING
  // ==========================================================

  static BookingStatus _statusFromString(
    String? value,
  ) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;

      case 'active':
        return BookingStatus.active;

      case 'completed':
        return BookingStatus.completed;

      case 'cancelled':
        return BookingStatus.cancelled;

      case 'noShow':
        return BookingStatus.noShow;

      case 'draft':
      default:
        return BookingStatus.draft;
    }
  }

  // ==========================================================
  // STATUS TO STRING
  // ==========================================================

  static String statusToString(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.draft:
        return 'draft';

      case BookingStatus.confirmed:
        return 'confirmed';

      case BookingStatus.active:
        return 'active';

      case BookingStatus.completed:
        return 'completed';

      case BookingStatus.cancelled:
        return 'cancelled';

      case BookingStatus.noShow:
        return 'noShow';
    }
  }

  // ==========================================================
  // PAYMENT STATUS FROM STRING
  // ==========================================================

  static PaymentStatus _paymentStatusFromString(
    String? value,
  ) {
    switch (value) {
      case 'partiallyPaid':
        return PaymentStatus.partiallyPaid;

      case 'paid':
        return PaymentStatus.paid;

      case 'refunded':
        return PaymentStatus.refunded;

      case 'unpaid':
      default:
        return PaymentStatus.unpaid;
    }
  }

  // ==========================================================
  // PAYMENT STATUS TO STRING
  // ==========================================================

  static String paymentStatusToString(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'unpaid';

      case PaymentStatus.partiallyPaid:
        return 'partiallyPaid';

      case PaymentStatus.paid:
        return 'paid';

      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  // ==========================================================
  // FUEL FROM STRING
  // ==========================================================

  static FuelLevel _fuelFromString(
    String? value,
  ) {
    switch (value) {
      case 'quarter':
        return FuelLevel.quarter;

      case 'half':
        return FuelLevel.half;

      case 'threeQuarter':
        return FuelLevel.threeQuarter;

      case 'full':
        return FuelLevel.full;

      case 'empty':
      default:
        return FuelLevel.empty;
    }
  }

  // ==========================================================
  // FUEL TO STRING
  // ==========================================================

  static String fuelToString(
    FuelLevel fuel,
  ) {
    switch (fuel) {
      case FuelLevel.empty:
        return 'empty';

      case FuelLevel.quarter:
        return 'quarter';

      case FuelLevel.half:
        return 'half';

      case FuelLevel.threeQuarter:
        return 'threeQuarter';

      case FuelLevel.full:
        return 'full';
    }
  }

  // ==========================================================
  // DATE HELPER
  // ==========================================================

  static DateTime? _timestampToDate(
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

  // ==========================================================
  // INT HELPER
  // ==========================================================

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

  // ==========================================================
  // DOUBLE HELPER
  // ==========================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ==========================================================
  // FROM FIRESTORE
  // ==========================================================

  factory BookingModel.fromFirestore(
    DocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? {};

    final now =
        DateTime.now();

    return BookingModel(
      id: doc.id,

      businessId:
          data['businessId'] ?? '',

      branchCode:
          data['branchCode'] ?? '',

      bookingNumber:
          data['bookingNumber'] ?? '',

      customerId:
          data['customerId'] ?? '',

      customerName:
          data['customerName'] ?? '',

      customerPhone:
          data['customerPhone'] ?? '',

      vehicleId:
          data['vehicleId'] ?? '',

      vehicleRegistrationNumber:
          data[
                'vehicleRegistrationNumber'] ??
              '',

      vehicleName:
          data['vehicleName'] ?? '',

      pickupDateTime:
          _timestampToDate(
                data[
                    'pickupDateTime'],
              ) ??
              now,

      returnDateTime:
          _timestampToDate(
                data[
                    'returnDateTime'],
              ) ??
              now,

      pickupLocation:
          data['pickupLocation'] ??
              '',

      returnLocation:
          data['returnLocation'] ??
              '',

      startingKm:
          _toInt(
        data['startingKm'],
      ),

      endingKm:
          data['endingKm'] == null
              ? null
              : _toInt(
                  data['endingKm'],
                ),

      fuelAtPickup:
          _fuelFromString(
        data['fuelAtPickup']
            ?.toString(),
      ),

      fuelAtReturn:
          data['fuelAtReturn'] == null
              ? null
              : _fuelFromString(
                  data['fuelAtReturn']
                      ?.toString(),
                ),

      dailyRate:
          _toDouble(
        data['dailyRate'],
      ),

      hourlyRate:
          data['hourlyRate'] == null
              ? null
              : _toDouble(
                  data['hourlyRate'],
                ),

      rentalDays:
          _toInt(
        data['rentalDays'],
      ),

      rentalHours:
          _toInt(
        data['rentalHours'],
      ),

      baseRentalAmount:
          _toDouble(
        data['baseRentalAmount'],
      ),

      securityDeposit:
          _toDouble(
        data['securityDeposit'],
      ),

      extraKmCharge:
          _toDouble(
        data['extraKmCharge'],
      ),

      fuelCharge:
          _toDouble(
        data['fuelCharge'],
      ),

      lateReturnCharge:
          _toDouble(
        data['lateReturnCharge'],
      ),

      damageCharge:
          _toDouble(
        data['damageCharge'],
      ),

      otherCharges:
          _toDouble(
        data['otherCharges'],
      ),

      discount:
          _toDouble(
        data['discount'],
      ),

      tax:
          _toDouble(
        data['tax'],
      ),

      totalAmount:
          _toDouble(
        data['totalAmount'],
      ),

      paidAmount:
          _toDouble(
        data['paidAmount'],
      ),

      pendingAmount:
          _toDouble(
        data['pendingAmount'],
      ),

      status:
          _statusFromString(
        data['status']
            ?.toString(),
      ),

      paymentStatus:
          _paymentStatusFromString(
        data['paymentStatus']
            ?.toString(),
      ),

      agreementNumber:
          data['agreementNumber'] ??
              '',

      termsAccepted:
          data['termsAccepted'] ??
              false,

      customerSignatureUrl:
          data[
              'customerSignatureUrl'],

      staffSignatureUrl:
          data[
              'staffSignatureUrl'],

      licenseNumber:
          data['licenseNumber'],

      licenseExpiryDate:
          _timestampToDate(
        data[
            'licenseExpiryDate'],
      ),

      licenseImageUrl:
          data['licenseImageUrl'],

      idProofType:
          data['idProofType'],

      idProofNumber:
          data['idProofNumber'],

      idProofImageUrl:
          data['idProofImageUrl'],

      createdBy:
          data['createdBy'] ?? '',

      confirmedBy:
          data['confirmedBy'],

      startedBy:
          data['startedBy'],

      completedBy:
          data['completedBy'],

      cancelledBy:
          data['cancelledBy'],

      customerNotes:
          data['customerNotes'],

      internalNotes:
          data['internalNotes'],

      createdAt:
          _timestampToDate(
                data['createdAt'],
              ) ??
              now,

      updatedAt:
          _timestampToDate(
                data['updatedAt'],
              ) ??
              now,

      confirmedAt:
          _timestampToDate(
        data['confirmedAt'],
      ),

      startedAt:
          _timestampToDate(
        data['startedAt'],
      ),

      completedAt:
          _timestampToDate(
        data['completedAt'],
      ),

      cancelledAt:
          _timestampToDate(
        data['cancelledAt'],
      ),
    );
  }

  // ==========================================================
  // TO FIRESTORE
  // ==========================================================

  Map<String, dynamic> toFirestore() {
    return {
      'businessId':
          businessId,

      'branchCode':
          branchCode,

      'bookingNumber':
          bookingNumber,

      'customerId':
          customerId,

      'customerName':
          customerName,

      'customerPhone':
          customerPhone,

      'vehicleId':
          vehicleId,

      'vehicleRegistrationNumber':
          vehicleRegistrationNumber,

      'vehicleName':
          vehicleName,

      'pickupDateTime':
          Timestamp.fromDate(
        pickupDateTime,
      ),

      'returnDateTime':
          Timestamp.fromDate(
        returnDateTime,
      ),

      'pickupLocation':
          pickupLocation,

      'returnLocation':
          returnLocation,

      'startingKm':
          startingKm,

      'endingKm':
          endingKm,

      'fuelAtPickup':
          fuelToString(
        fuelAtPickup,
      ),

      'fuelAtReturn':
          fuelAtReturn == null
              ? null
              : fuelToString(
                  fuelAtReturn!,
                ),

      'dailyRate':
          dailyRate,

      'hourlyRate':
          hourlyRate,

      'rentalDays':
          rentalDays,

      'rentalHours':
          rentalHours,

      'baseRentalAmount':
          baseRentalAmount,

      'securityDeposit':
          securityDeposit,

      'extraKmCharge':
          extraKmCharge,

      'fuelCharge':
          fuelCharge,

      'lateReturnCharge':
          lateReturnCharge,

      'damageCharge':
          damageCharge,

      'otherCharges':
          otherCharges,

      'discount':
          discount,

      'tax':
          tax,

      'totalAmount':
          totalAmount,

      'paidAmount':
          paidAmount,

      'pendingAmount':
          pendingAmount,

      'status':
          statusToString(
        status,
      ),

      'paymentStatus':
          paymentStatusToString(
        paymentStatus,
      ),

      'agreementNumber':
          agreementNumber,

      'termsAccepted':
          termsAccepted,

      'customerSignatureUrl':
          customerSignatureUrl,

      'staffSignatureUrl':
          staffSignatureUrl,

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

      'createdBy':
          createdBy,

      'confirmedBy':
          confirmedBy,

      'startedBy':
          startedBy,

      'completedBy':
          completedBy,

      'cancelledBy':
          cancelledBy,

      'customerNotes':
          customerNotes,

      'internalNotes':
          internalNotes,

      'createdAt':
          Timestamp.fromDate(
        createdAt,
      ),

      'updatedAt':
          Timestamp.fromDate(
        updatedAt,
      ),

      'confirmedAt':
          confirmedAt == null
              ? null
              : Timestamp.fromDate(
                  confirmedAt!,
                ),

      'startedAt':
          startedAt == null
              ? null
              : Timestamp.fromDate(
                  startedAt!,
                ),

      'completedAt':
          completedAt == null
              ? null
              : Timestamp.fromDate(
                  completedAt!,
                ),

      'cancelledAt':
          cancelledAt == null
              ? null
              : Timestamp.fromDate(
                  cancelledAt!,
                ),
    };
  }

  // ==========================================================
  // AVAILABILITY OVERLAP
  //
  // Returns TRUE when this booking overlaps the requested
  // rental period.
  //
  // Example:
  //
  // Existing: 10:00 → 18:00
  // Requested: 14:00 → 20:00
  //
  // TRUE = conflict
  // ==========================================================

  bool overlaps(
    DateTime requestedPickup,
    DateTime requestedReturn,
  ) {
    return pickupDateTime
            .isBefore(requestedReturn) &&
        returnDateTime
            .isAfter(requestedPickup);
  }

  // ==========================================================
  // SHOULD BLOCK AVAILABILITY
  //
  // Cancelled and no-show bookings do not block the vehicle.
  // Draft bookings also do not block until confirmed.
  // ==========================================================

  bool get blocksAvailability {
    return status ==
            BookingStatus.confirmed ||
        status ==
            BookingStatus.active;
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  BookingModel copyWith({
    String? businessId,
    String? branchCode,
    String? bookingNumber,

    String? customerId,
    String? customerName,
    String? customerPhone,

    String? vehicleId,
    String? vehicleRegistrationNumber,
    String? vehicleName,

    DateTime? pickupDateTime,
    DateTime? returnDateTime,

    String? pickupLocation,
    String? returnLocation,

    int? startingKm,
    int? endingKm,

    FuelLevel? fuelAtPickup,
    FuelLevel? fuelAtReturn,

    double? dailyRate,
    double? hourlyRate,

    int? rentalDays,
    int? rentalHours,

    double? baseRentalAmount,
    double? securityDeposit,

    double? extraKmCharge,
    double? fuelCharge,
    double? lateReturnCharge,
    double? damageCharge,
    double? otherCharges,

    double? discount,
    double? tax,

    double? totalAmount,
    double? paidAmount,
    double? pendingAmount,

    BookingStatus? status,
    PaymentStatus? paymentStatus,

    String? agreementNumber,
    bool? termsAccepted,

    String? customerSignatureUrl,
    String? staffSignatureUrl,

    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? licenseImageUrl,

    String? idProofType,
    String? idProofNumber,
    String? idProofImageUrl,

    String? createdBy,
    String? confirmedBy,
    String? startedBy,
    String? completedBy,
    String? cancelledBy,

    String? customerNotes,
    String? internalNotes,

    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return BookingModel(
      id: id,

      businessId:
          businessId ??
              this.businessId,

      branchCode:
          branchCode ??
              this.branchCode,

      bookingNumber:
          bookingNumber ??
              this.bookingNumber,

      customerId:
          customerId ??
              this.customerId,

      customerName:
          customerName ??
              this.customerName,

      customerPhone:
          customerPhone ??
              this.customerPhone,

      vehicleId:
          vehicleId ??
              this.vehicleId,

      vehicleRegistrationNumber:
          vehicleRegistrationNumber ??
              this.vehicleRegistrationNumber,

      vehicleName:
          vehicleName ??
              this.vehicleName,

      pickupDateTime:
          pickupDateTime ??
              this.pickupDateTime,

      returnDateTime:
          returnDateTime ??
              this.returnDateTime,

      pickupLocation:
          pickupLocation ??
              this.pickupLocation,

      returnLocation:
          returnLocation ??
              this.returnLocation,

      startingKm:
          startingKm ??
              this.startingKm,

      endingKm:
          endingKm ??
              this.endingKm,

      fuelAtPickup:
          fuelAtPickup ??
              this.fuelAtPickup,

      fuelAtReturn:
          fuelAtReturn ??
              this.fuelAtReturn,

      dailyRate:
          dailyRate ??
              this.dailyRate,

      hourlyRate:
          hourlyRate ??
              this.hourlyRate,

      rentalDays:
          rentalDays ??
              this.rentalDays,

      rentalHours:
          rentalHours ??
              this.rentalHours,

      baseRentalAmount:
          baseRentalAmount ??
              this.baseRentalAmount,

      securityDeposit:
          securityDeposit ??
              this.securityDeposit,

      extraKmCharge:
          extraKmCharge ??
              this.extraKmCharge,

      fuelCharge:
          fuelCharge ??
              this.fuelCharge,

      lateReturnCharge:
          lateReturnCharge ??
              this.lateReturnCharge,

      damageCharge:
          damageCharge ??
              this.damageCharge,

      otherCharges:
          otherCharges ??
              this.otherCharges,

      discount:
          discount ??
              this.discount,

      tax:
          tax ??
              this.tax,

      totalAmount:
          totalAmount ??
              this.totalAmount,

      paidAmount:
          paidAmount ??
              this.paidAmount,

      pendingAmount:
          pendingAmount ??
              this.pendingAmount,

      status:
          status ??
              this.status,

      paymentStatus:
          paymentStatus ??
              this.paymentStatus,

      agreementNumber:
          agreementNumber ??
              this.agreementNumber,

      termsAccepted:
          termsAccepted ??
              this.termsAccepted,

      customerSignatureUrl:
          customerSignatureUrl ??
              this.customerSignatureUrl,

      staffSignatureUrl:
          staffSignatureUrl ??
              this.staffSignatureUrl,

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

      createdBy:
          createdBy ??
              this.createdBy,

      confirmedBy:
          confirmedBy ??
              this.confirmedBy,

      startedBy:
          startedBy ??
              this.startedBy,

      completedBy:
          completedBy ??
              this.completedBy,

      cancelledBy:
          cancelledBy ??
              this.cancelledBy,

      customerNotes:
          customerNotes ??
              this.customerNotes,

      internalNotes:
          internalNotes ??
              this.internalNotes,

      createdAt:
          createdAt,

      updatedAt:
          updatedAt ??
              this.updatedAt,

      confirmedAt:
          confirmedAt ??
              this.confirmedAt,

      startedAt:
          startedAt ??
              this.startedAt,

      completedAt:
          completedAt ??
              this.completedAt,

      cancelledAt:
          cancelledAt ??
              this.cancelledAt,
    );
  }
}

