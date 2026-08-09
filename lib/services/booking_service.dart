
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';

class BookingService {
  BookingService._();

  static final BookingService instance =
      BookingService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _bookings =>
          _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>>
      get _vehicles =>
          _firestore.collection('vehicles');

  CollectionReference<Map<String, dynamic>>
      get _users =>
          _firestore.collection('users');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // GET CURRENT USER MODEL
  //
  // One read.
  // Used to obtain businessId + branchCode.
  // ============================================================

  Future<UserModel> _getCurrentUserModel() async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final snapshot =
        await _users.doc(user.uid).get();

    if (!snapshot.exists) {
      throw Exception(
        'User profile not found.',
      );
    }

    return UserModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // CHECK AVAILABILITY
  //
  // Checks future bookings for ONE vehicle.
  //
  // IMPORTANT:
  // This checks exact DateTime ranges.
  //
  // Conflict condition:
  //
  // existingPickup < requestedReturn
  // &&
  // existingReturn > requestedPickup
  //
  // This supports:
  // - hourly rentals
  // - same-day rentals
  // - overnight rentals
  // - multi-day rentals
  // - future bookings
  // ============================================================

  Future<BookingAvailabilityResult>
      checkAvailability({
    required String vehicleId,
    required DateTime requestedPickup,
    required DateTime requestedReturn,
    String? excludeBookingId,
  }) async {
    if (requestedReturn
        .isBefore(requestedPickup) ||
        requestedReturn.isAtSameMomentAs(
          requestedPickup,
        )) {
      throw Exception(
        'Return time must be after pickup time.',
      );
    }

    final user =
        await _getCurrentUserModel();

    final branchCode =
        user.branchCode;

    final businessId =
        user.businessId;

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

    // ----------------------------------------------------------
    // Query bookings for this exact vehicle and branch.
    //
    // We intentionally do NOT read all bookings.
    // Only this vehicle's relevant bookings are queried.
    // ----------------------------------------------------------

    Query<Map<String, dynamic>> query =
        _bookings
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
              'vehicleId',
              isEqualTo:
                  vehicleId,
            )
            .where(
              'status',
              whereIn: [
                'confirmed',
                'active',
              ],
            );

    final snapshot =
        await query.get();

    final conflicts =
        <BookingModel>[];

    for (final document
        in snapshot.docs) {
      final booking =
          BookingModel.fromFirestore(
        document,
      );

      if (excludeBookingId != null &&
          booking.id ==
              excludeBookingId) {
        continue;
      }

      if (booking.overlaps(
        requestedPickup,
        requestedReturn,
      )) {
        conflicts.add(
          booking,
        );
      }
    }

    if (conflicts.isEmpty) {
      return BookingAvailabilityResult.available();
    }

    // ----------------------------------------------------------
    // Sort conflicts by pickup time.
    // ----------------------------------------------------------

    conflicts.sort(
      (a, b) =>
          a.pickupDateTime
              .compareTo(
        b.pickupDateTime,
      ),
    );

    return BookingAvailabilityResult.unavailable(
      conflicts: conflicts,
    );
  }

  // ============================================================
  // GET BOOKINGS FOR CALENDAR
  //
  // Used by the calendar screen.
  //
  // Returns only confirmed + active bookings for one vehicle
  // inside the requested calendar window.
  // ============================================================

  Future<List<BookingModel>>
      getVehicleBookingsForCalendar({
    required String vehicleId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (rangeEnd
        .isBefore(rangeStart)) {
      throw Exception(
        'Invalid calendar range.',
      );
    }

    final user =
        await _getCurrentUserModel();

    final businessId =
        user.businessId;

    final branchCode =
        user.branchCode;

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

    // ----------------------------------------------------------
    // Query bookings that start before the calendar range ends.
    //
    // We then check the other side of the overlap locally.
    //
    // This allows bookings that started before the calendar
    // month but continue into it to be displayed correctly.
    // ----------------------------------------------------------

    final snapshot =
        await _bookings
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
              'vehicleId',
              isEqualTo:
                  vehicleId,
            )
            .where(
              'status',
              whereIn: [
                'confirmed',
                'active',
              ],
            )
            .where(
              'pickupDateTime',
              isLessThan:
                  Timestamp.fromDate(
                rangeEnd,
              ),
            )
            .orderBy(
              'pickupDateTime',
            )
            .get();

    final results =
        <BookingModel>[];

    for (final document
        in snapshot.docs) {
      final booking =
          BookingModel.fromFirestore(
        document,
      );

      // --------------------------------------------------------
      // Only include bookings that actually overlap the
      // requested calendar window.
      // --------------------------------------------------------

      if (booking.returnDateTime
              .isAfter(rangeStart) &&
          booking.pickupDateTime
              .isBefore(rangeEnd)) {
        results.add(
          booking,
        );
      }
    }

    return results;
  }

// ============================================================
// CHECK BRANCH AVAILABILITY
//
// Returns ALL vehicles in the current branch that are available
// for the requested pickup -> return DateTime range.
//
// This is used by:
//
// Dashboard
//    ↓
// BranchAvailabilityScreen
//    ↓
// All available vehicles
//
// IMPORTANT:
// We reuse the same BookingService and the same overlap logic
// used by checkAvailability().
//
// Supported:
// - hourly rentals
// - same-day rentals
// - overnight rentals
// - multi-day rentals
// - future bookings
// ============================================================

Future<List<VehicleModel>>
    checkBranchAvailability({
  required DateTime requestedPickup,
  required DateTime requestedReturn,
}) async {
  // ----------------------------------------------------------
  // VALIDATE DATE/TIME
  // ----------------------------------------------------------

  if (requestedReturn
      .isBefore(requestedPickup) ||
      requestedReturn.isAtSameMomentAs(
        requestedPickup,
      )) {
    throw Exception(
      'Return time must be after pickup time.',
    );
  }

  // ----------------------------------------------------------
  // GET CURRENT USER
  //
  // This is the same method already used everywhere else
  // in BookingService.
  // ----------------------------------------------------------

  final user =
      await _getCurrentUserModel();

  final businessId =
      user.businessId;

  final branchCode =
      user.branchCode;

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

  // ----------------------------------------------------------
  // STEP 1
  // GET ACTIVE VEHICLES FOR THIS BRANCH
  //
  // We do NOT read vehicles from other businesses/branches.
  // ----------------------------------------------------------

  final vehicleSnapshot =
      await _vehicles
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
            'isActive',
            isEqualTo:
                true,
          )
          .get();

  if (vehicleSnapshot.docs.isEmpty) {
    return [];
  }

  final vehicles =
      vehicleSnapshot.docs
          .map(
            (doc) =>
                VehicleModel.fromFirestore(
              doc,
            ),
          )
          .toList();

  // ----------------------------------------------------------
  // STEP 2
  // REMOVE VEHICLES THAT ARE NOT RENTABLE
  //
  // Maintenance and inactive vehicles can never appear as
  // available.
  // ----------------------------------------------------------

  final rentableVehicles =
      vehicles.where(
    (vehicle) {
      return vehicle.isActive &&
          vehicle.status !=
              VehicleStatus.maintenance &&
          vehicle.status !=
              VehicleStatus.inactive;
    },
  ).toList();

  if (rentableVehicles.isEmpty) {
    return [];
  }

  // ----------------------------------------------------------
  // STEP 3
  // GET VEHICLE IDS
  // ----------------------------------------------------------

  final vehicleIds =
      rentableVehicles
          .map(
            (vehicle) =>
                vehicle.id,
          )
          .toSet();

  // ----------------------------------------------------------
  // STEP 4
  // GET RELEVANT BOOKINGS
  //
  // IMPORTANT:
  //
  // We only need bookings that:
  //
  // pickupDateTime < requestedReturn
  //
  // because a booking that starts after the requested return
  // cannot overlap.
  //
  // The second side of the overlap is checked locally:
  //
  // booking.returnDateTime > requestedPickup
  //
  // This also handles bookings that started before the requested
  // period but continue into it.
  // ----------------------------------------------------------

  final bookingSnapshot =
      await _bookings
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
            'status',
            whereIn: [
              'confirmed',
              'active',
            ],
          )
          .where(
            'pickupDateTime',
            isLessThan:
                Timestamp.fromDate(
              requestedReturn,
            ),
          )
          .orderBy(
            'pickupDateTime',
          )
          .get();

  // ----------------------------------------------------------
  // STEP 5
  // FIND VEHICLES WITH CONFLICTING BOOKINGS
  // ----------------------------------------------------------

  final unavailableVehicleIds =
      <String>{};

  for (final document
      in bookingSnapshot.docs) {
    final booking =
        BookingModel.fromFirestore(
      document,
    );

    // --------------------------------------------------------
    // Ignore bookings for vehicles that are not currently
    // rentable vehicles in this branch.
    // --------------------------------------------------------

    if (!vehicleIds.contains(
      booking.vehicleId,
    )) {
      continue;
    }

    // --------------------------------------------------------
    // EXACT OVERLAP CHECK
    //
    // Reuses BookingModel.overlaps(), exactly like the existing
    // checkAvailability() method.
    // --------------------------------------------------------

    if (booking.overlaps(
      requestedPickup,
      requestedReturn,
    )) {
      unavailableVehicleIds.add(
        booking.vehicleId,
      );
    }
  }

  // ----------------------------------------------------------
  // STEP 6
  // RETURN AVAILABLE VEHICLES
  // ----------------------------------------------------------

  final availableVehicles =
      rentableVehicles.where(
    (vehicle) {
      return !unavailableVehicleIds
          .contains(
        vehicle.id,
      );
    },
  ).toList();

  // ----------------------------------------------------------
  // SORT
  //
  // Available vehicles first remain naturally ordered by the
  // Firestore query.
  //
  // We can later add sorting by:
  // - price
  // - vehicle type
  // - model
  // - availability
  // ----------------------------------------------------------

  return availableVehicles;
}



  // ============================================================
  // GET VEHICLE
  //
  // Used during booking creation.
  // ============================================================

  Future<VehicleModel>
      getVehicle(
    String vehicleId,
  ) async {
    final snapshot =
        await _vehicles
            .doc(vehicleId)
            .get();

    if (!snapshot.exists) {
      throw Exception(
        'Vehicle not found.',
      );
    }

    return VehicleModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // CREATE BOOKING
  //
  // IMPORTANT:
  // We perform the availability check immediately before
  // creating the booking.
  //
  // For production-grade double-booking protection, this
  // operation should ultimately be moved to a trusted backend
  // transaction / Cloud Function because Firestore cannot
  // transactionally lock an arbitrary range of booking
  // documents.
  // ============================================================

  Future<BookingModel>
      createBooking({
    required String customerId,
    required String customerName,
    required String customerPhone,

    required String vehicleId,

    required DateTime pickupDateTime,
    required DateTime returnDateTime,

    required String pickupLocation,
    required String returnLocation,

    required int startingKm,

    required FuelLevel fuelAtPickup,

    required double dailyRate,
    double? hourlyRate,

    required int rentalDays,
    required int rentalHours,

    required double baseRentalAmount,
    required double securityDeposit,

    double extraKmCharge = 0,
    double fuelCharge = 0,
    double lateReturnCharge = 0,
    double damageCharge = 0,
    double otherCharges = 0,

    double discount = 0,
    double tax = 0,

    required double totalAmount,

    double paidAmount = 0,

    required String agreementNumber,

    bool termsAccepted = false,

    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? licenseImageUrl,

    String? idProofType,
    String? idProofNumber,
    String? idProofImageUrl,

    String? customerNotes,
    String? internalNotes,
  }) async {
    // ----------------------------------------------------------
    // Validate dates first.
    // ----------------------------------------------------------

    if (!returnDateTime
        .isAfter(pickupDateTime)) {
      throw Exception(
        'Return time must be after pickup time.',
      );
    }

    // ----------------------------------------------------------
    // Get logged-in user.
    // ----------------------------------------------------------

    final user =
        await _getCurrentUserModel();

    final businessId =
        user.businessId;

    final branchCode =
        user.branchCode;

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

    final uid =
        currentUser!.uid;

    // ----------------------------------------------------------
    // Get vehicle.
    //
    // One read.
    // ----------------------------------------------------------

    final vehicle =
        await getVehicle(
      vehicleId,
    );

    if (vehicle.businessId !=
            businessId ||
        vehicle.branchCode !=
            branchCode) {
      throw Exception(
        'This vehicle does not belong to your branch.',
      );
    }

    if (!vehicle.isActive) {
      throw Exception(
        'This vehicle is inactive.',
      );
    }

    if (vehicle.status ==
        VehicleStatus.maintenance) {
      throw Exception(
        'This vehicle is currently under maintenance.',
      );
    }

    if (vehicle.status ==
        VehicleStatus.inactive) {
      throw Exception(
        'This vehicle is inactive.',
      );
    }

    // ----------------------------------------------------------
    // FINAL AVAILABILITY CHECK
    //
    // This protects against the user reaching this point
    // after another booking was already created.
    // ----------------------------------------------------------

    final availability =
        await checkAvailability(
      vehicleId:
          vehicleId,
      requestedPickup:
          pickupDateTime,
      requestedReturn:
          returnDateTime,
    );

    if (!availability.isAvailable) {
      throw BookingConflictException(
        availability.conflicts,
      );
    }

    // ----------------------------------------------------------
    // Generate IDs.
    // ----------------------------------------------------------

    final bookingRef =
        _bookings.doc();

    final bookingNumber =
        await _generateBookingNumber(
      branchCode:
          branchCode,
    );

    final now =
        DateTime.now();

    // ----------------------------------------------------------
    // Payment status.
    // ----------------------------------------------------------

    final paymentStatus =
        _calculatePaymentStatus(
      totalAmount:
          totalAmount,
      paidAmount:
          paidAmount,
    );

    // ----------------------------------------------------------
    // Create model.
    // ----------------------------------------------------------

    final booking =
        BookingModel(
      id:
          bookingRef.id,

      businessId:
          businessId,

      branchCode:
          branchCode,

      bookingNumber:
          bookingNumber,

      customerId:
          customerId,

      customerName:
          customerName,

      customerPhone:
          customerPhone,

      vehicleId:
          vehicleId,

      vehicleRegistrationNumber:
          vehicle.registrationNumber,

      vehicleName:
          _vehicleName(
        vehicle,
      ),

      pickupDateTime:
          pickupDateTime,

      returnDateTime:
          returnDateTime,

      pickupLocation:
          pickupLocation,

      returnLocation:
          returnLocation,

      startingKm:
          startingKm,

      endingKm:
          null,

      fuelAtPickup:
          fuelAtPickup,

      fuelAtReturn:
          null,

      dailyRate:
          dailyRate,

      hourlyRate:
          hourlyRate,

      rentalDays:
          rentalDays,

      rentalHours:
          rentalHours,

      baseRentalAmount:
          baseRentalAmount,

      securityDeposit:
          securityDeposit,

      extraKmCharge:
          extraKmCharge,

      fuelCharge:
          fuelCharge,

      lateReturnCharge:
          lateReturnCharge,

      damageCharge:
          damageCharge,

      otherCharges:
          otherCharges,

      discount:
          discount,

      tax:
          tax,

      totalAmount:
          totalAmount,

      paidAmount:
          paidAmount,

      pendingAmount:
          _calculatePendingAmount(
        totalAmount:
            totalAmount,
        paidAmount:
            paidAmount,
      ),

      status:
          BookingStatus.confirmed,

      paymentStatus:
          paymentStatus,

      agreementNumber:
          agreementNumber,

      termsAccepted:
          termsAccepted,

      customerSignatureUrl:
          null,

      staffSignatureUrl:
          null,

      licenseNumber:
          licenseNumber,

      licenseExpiryDate:
          licenseExpiryDate,

      licenseImageUrl:
          licenseImageUrl,

      idProofType:
          idProofType,

      idProofNumber:
          idProofNumber,

      idProofImageUrl:
          idProofImageUrl,

      createdBy:
          uid,

      confirmedBy:
          uid,

      startedBy:
          null,

      completedBy:
          null,

      cancelledBy:
          null,

      customerNotes:
          customerNotes,

      internalNotes:
          internalNotes,

      createdAt:
          now,

      updatedAt:
          now,

      confirmedAt:
          now,

      startedAt:
          null,

      completedAt:
          null,

      cancelledAt:
          null,
    );

    // ----------------------------------------------------------
    // WRITE BOOKING
    // ----------------------------------------------------------

    await bookingRef.set(
      booking.toFirestore(),
    );

    // ----------------------------------------------------------
    // UPDATE VEHICLE
    //
    // IMPORTANT:
    // We only change fields that are related to the current
    // booking.
    // ----------------------------------------------------------

    await _vehicles
        .doc(vehicleId)
        .update({
      'status':
          'reserved',

      'currentBookingId':
          bookingRef.id,

      'nextBookingStartAt':
          Timestamp.fromDate(
        pickupDateTime,
      ),

      'nextBookingEndAt':
          Timestamp.fromDate(
        returnDateTime,
      ),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return booking;
  }

  // ============================================================
  // GENERATE BOOKING NUMBER
  //
  // Example:
  //
  // MH12-20260809-0001
  //
  // NOTE:
  // For very high concurrency, this counter should be replaced
  // by a dedicated transactional counter.
  // ============================================================

  Future<String>
      _generateBookingNumber({
    required String branchCode,
  }) async {
    final date =
        DateTime.now();

    final dateString =
        '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final counterRef =
        _firestore
            .collection(
              'bookingCounters',
            )
            .doc(
              '${branchCode}_$dateString',
            );

    final nextNumber =
        await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          counterRef,
        );

        int current =
            0;

        if (snapshot.exists) {
          final data =
              snapshot.data();

          current =
              (data?['lastNumber']
                          as num?)
                      ?.toInt() ??
                  0;
        }

        final next =
            current + 1;

        transaction.set(
          counterRef,
          {
            'branchCode':
                branchCode,
            'date':
                dateString,
            'lastNumber':
                next,
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        return next;
      },
    );

    return '$branchCode-$dateString-${nextNumber.toString().padLeft(4, '0')}';
  }

  // ============================================================
  // CALCULATE PAYMENT STATUS
  // ============================================================

  PaymentStatus
      _calculatePaymentStatus({
    required double totalAmount,
    required double paidAmount,
  }) {
    if (paidAmount <= 0) {
      return PaymentStatus.unpaid;
    }

    if (paidAmount >=
        totalAmount) {
      return PaymentStatus.paid;
    }

    return PaymentStatus.partiallyPaid;
  }

  // ============================================================
  // CALCULATE PENDING
  // ============================================================

  double
      _calculatePendingAmount({
    required double totalAmount,
    required double paidAmount,
  }) {
    final pending =
        totalAmount -
            paidAmount;

    if (pending < 0) {
      return 0;
    }

    return pending;
  }

  // ============================================================
  // VEHICLE NAME
  // ============================================================

  String _vehicleName(
    VehicleModel vehicle,
  ) {
    final parts = [
      vehicle.make,
      vehicle.model,
      vehicle.variant,
    ].where(
      (value) =>
          value.trim().isNotEmpty,
    );

    return parts.join(' ');
  }
}

// ============================================================
// AVAILABILITY RESULT
// ============================================================

class BookingAvailabilityResult {
  final bool isAvailable;

  final List<BookingModel> conflicts;

  const BookingAvailabilityResult({
    required this.isAvailable,
    required this.conflicts,
  });

  factory BookingAvailabilityResult.available() {
    return const BookingAvailabilityResult(
      isAvailable: true,
      conflicts: [],
    );
  }

  factory BookingAvailabilityResult.unavailable({
    required List<BookingModel> conflicts,
  }) {
    return BookingAvailabilityResult(
      isAvailable: false,
      conflicts: conflicts,
    );
  }

  BookingModel? get firstConflict {
    if (conflicts.isEmpty) {
      return null;
    }

    return conflicts.first;
  }
}

// ============================================================
// BOOKING CONFLICT EXCEPTION
// ============================================================

class BookingConflictException
    implements Exception {
  final List<BookingModel> conflicts;

  const BookingConflictException(
    this.conflicts,
  );

  BookingModel? get firstConflict {
    if (conflicts.isEmpty) {
      return null;
    }

    return conflicts.first;
  }

  @override
  String toString() {
    if (conflicts.isEmpty) {
      return 'Vehicle is not available for the selected period.';
    }

    final first =
        conflicts.first;

    return 'Vehicle is already booked from '
        '${first.pickupDateTime} to '
        '${first.returnDateTime}.';
  }
}

