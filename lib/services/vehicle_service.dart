
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vehicle_model.dart';

class VehicleService {
  VehicleService._();

  static final VehicleService instance =
      VehicleService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CREATE VEHICLE
  //
  // FLOW:
  //
  // users/{uid}
  //      ↓
  // businessId + branchCode
  //      ↓
  // check registration
  //      ↓
  // vehicles/{vehicleId}
  //      ↓
  // dashboardStats/{branchCode}
  //
  // New vehicle always starts as AVAILABLE.
  // ============================================================

  Future<String> createVehicle({
    required String registrationNumber,
    required String make,
    required String model,
    required String variant,
    required String vehicleType,
    required String fuelType,
    required String transmission,
    required int year,
    required String color,
    required int currentKm,
    required double dailyRate,
    required double weeklyRate,
    required double monthlyRate,
    required double securityDeposit,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    // ==========================================================
    // NORMALIZE
    // ==========================================================

    final normalizedRegistration =
        registrationNumber
            .trim()
            .toUpperCase();

    final normalizedMake =
        make.trim();

    final normalizedModel =
        model.trim();

    final normalizedVariant =
        variant.trim();

    final normalizedVehicleType =
        vehicleType
            .trim()
            .toLowerCase();

    final normalizedFuelType =
        fuelType
            .trim()
            .toLowerCase();

    final normalizedTransmission =
        transmission
            .trim()
            .toLowerCase();

    final normalizedColor =
        color.trim();

    final normalizedImageUrl =
        imageUrl?.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (normalizedRegistration.isEmpty) {
      throw Exception(
        'Vehicle registration number is required.',
      );
    }

    if (normalizedMake.isEmpty) {
      throw Exception(
        'Vehicle make is required.',
      );
    }

    if (normalizedModel.isEmpty) {
      throw Exception(
        'Vehicle model is required.',
      );
    }

    if (normalizedVariant.isEmpty) {
      throw Exception(
        'Vehicle variant is required.',
      );
    }

    if (normalizedVehicleType.isEmpty) {
      throw Exception(
        'Vehicle type is required.',
      );
    }

    if (normalizedFuelType.isEmpty) {
      throw Exception(
        'Fuel type is required.',
      );
    }

    if (normalizedTransmission.isEmpty) {
      throw Exception(
        'Transmission type is required.',
      );
    }

    if (normalizedColor.isEmpty) {
      throw Exception(
        'Vehicle color is required.',
      );
    }

    if (year < 1900 ||
        year > DateTime.now().year + 1) {
      throw Exception(
        'Invalid vehicle year.',
      );
    }

    if (currentKm < 0) {
      throw Exception(
        'Current KM cannot be negative.',
      );
    }

    if (dailyRate <= 0) {
      throw Exception(
        'Daily rental rate must be greater than zero.',
      );
    }

    if (weeklyRate < 0) {
      throw Exception(
        'Weekly rental rate cannot be negative.',
      );
    }

    if (monthlyRate < 0) {
      throw Exception(
        'Monthly rental rate cannot be negative.',
      );
    }

    if (securityDeposit < 0) {
      throw Exception(
        'Security deposit cannot be negative.',
      );
    }

    // ==========================================================
    // USER REFERENCE
    // ==========================================================

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    // ==========================================================
    // GET USER CONTEXT
    //
    // 1 READ
    // ==========================================================

    final userSnapshot =
        await userRef.get();

    if (!userSnapshot.exists) {
      throw Exception(
        'User profile not found.',
      );
    }

    final userData =
        userSnapshot.data();

    if (userData == null) {
      throw Exception(
        'User profile is empty.',
      );
    }

    final businessId =
        userData['businessId']
            ?.toString();

    final branchCode =
        userData['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (businessId == null ||
        businessId.isEmpty) {
      throw Exception(
        'Business setup is incomplete.',
      );
    }

    if (branchCode == null ||
        branchCode.isEmpty) {
      throw Exception(
        'Branch setup is incomplete.',
      );
    }

    // ==========================================================
    // VEHICLE REGISTRATION KEY
    //
    // Used only for duplicate protection.
    //
    // Example:
    //
    // vehicleKeys/RCR001_MH12AB1234
    //
    // This keeps registration numbers unique per branch.
    // ==========================================================

    final registrationKey =
        '${branchCode}_${normalizedRegistration}'
            .replaceAll(
              '/',
              '_',
            );

    final registrationKeyRef =
        _firestore
            .collection('vehicleKeys')
            .doc(registrationKey);

    // ==========================================================
    // VEHICLE REFERENCE
    // ==========================================================

    final vehicleRef = _firestore
        .collection('vehicles')
        .doc();

    // ==========================================================
    // DASHBOARD REFERENCE
    // ==========================================================

    final statsRef = _firestore
        .collection('dashboardStats')
        .doc(branchCode);

    // ==========================================================
    // TIMESTAMP
    // ==========================================================

    final now =
        DateTime.now();

    // ==========================================================
    // VEHICLE MODEL
    // ==========================================================

    final vehicle =
        VehicleModel(
      id:
          vehicleRef.id,

      businessId:
          businessId,

      branchCode:
          branchCode,

      registrationNumber:
          normalizedRegistration,

      make:
          normalizedMake,

      model:
          normalizedModel,

      variant:
          normalizedVariant,

      vehicleType:
          normalizedVehicleType,

      fuelType:
          normalizedFuelType,

      transmission:
          normalizedTransmission,

      year:
          year,

      color:
          normalizedColor,

      currentKm:
          currentKm,

      dailyRate:
          dailyRate,

      weeklyRate:
          weeklyRate,

      monthlyRate:
          monthlyRate,

      securityDeposit:
          securityDeposit,

      status:
          VehicleStatus.available,

      isActive:
          true,

      imageUrl:
          normalizedImageUrl?.isEmpty == true
              ? null
              : normalizedImageUrl,

      createdAt:
          now,

      updatedAt:
          now,
    );

    // ==========================================================
    // ATOMIC CREATE
    //
    // READS:
    // 1. registration key
    // 2. dashboard stats
    //
    // WRITES:
    // 1. vehicle
    // 2. registration key
    // 3. dashboard stats
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ REGISTRATION KEY
        // --------------------------------------------------------

        final registrationSnapshot =
            await transaction.get(
          registrationKeyRef,
        );

        if (registrationSnapshot.exists) {
          throw Exception(
            'A vehicle with this registration number already exists in this branch.',
          );
        }

        // --------------------------------------------------------
        // READ DASHBOARD STATS
        // --------------------------------------------------------

        final statsSnapshot =
            await transaction.get(
          statsRef,
        );

        // --------------------------------------------------------
        // CREATE VEHICLE
        // --------------------------------------------------------

        transaction.set(
          vehicleRef,
          vehicle.toFirestore(),
        );

        // --------------------------------------------------------
        // RESERVE REGISTRATION NUMBER
        // --------------------------------------------------------

        transaction.set(
          registrationKeyRef,
          {
            'vehicleId':
                vehicleRef.id,

            'businessId':
                businessId,

            'branchCode':
                branchCode,

            'registrationNumber':
                normalizedRegistration,

            'createdAt':
                Timestamp.fromDate(
              now,
            ),
          },
        );

        // --------------------------------------------------------
        // UPDATE DASHBOARD
        // --------------------------------------------------------

        if (statsSnapshot.exists) {
          transaction.update(
            statsRef,
            {
              'totalVehicles':
                  FieldValue.increment(1),

              'availableVehicles':
                  FieldValue.increment(1),

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        } else {
          transaction.set(
            statsRef,
            {
              'branchCode':
                  branchCode,

              'totalVehicles':
                  1,

              'availableVehicles':
                  1,

              'reservedVehicles':
                  0,

              'rentedVehicles':
                  0,

              'maintenanceVehicles':
                  0,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        }
      },
    );

    return vehicleRef.id;
  }

  // ============================================================
  // GET VEHICLES
  //
  // PAGINATED
  //
  // Default:
  // 15 vehicles per request.
  //
  // NEVER load the entire fleet.
  // ============================================================

  Future<
      QuerySnapshot<
          Map<String, dynamic>>> getVehicles({
    required String branchCode,
    int limit = 15,
    DocumentSnapshot<
            Map<String, dynamic>>?
        startAfter,
  }) async {
    final normalizedCode =
        branchCode
            .trim()
            .toUpperCase();

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Branch code is required.',
      );
    }

    if (limit <= 0) {
      limit = 15;
    }

    if (limit > 30) {
      limit = 30;
    }

    Query<
        Map<String, dynamic>> query =
        _firestore
            .collection('vehicles')
            .where(
              'branchCode',
              isEqualTo:
                  normalizedCode,
            )
            .where(
              'isActive',
              isEqualTo: true,
            )
            .orderBy(
              'updatedAt',
              descending: true,
            )
            .limit(limit);

    if (startAfter != null) {
      query =
          query.startAfterDocument(
        startAfter,
      );
    }

    return query.get();
  }

  // ============================================================
  // GET SINGLE VEHICLE
  //
  // 1 READ
  //
  // NOTE:
  // Firestore Security Rules must also protect branch access.
  // ============================================================

  Future<VehicleModel?>
      getVehicle(
    String vehicleId,
  ) async {
    final id =
        vehicleId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('vehicles')
            .doc(id)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return VehicleModel.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // UPDATE VEHICLE
  //
  // Branch-safe.
  //
  // We NEVER allow:
  //
  // businessId
  // branchCode
  // status
  // createdAt
  //
  // to be changed through this method.
  // ============================================================

  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> updates,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    if (updates.isEmpty) {
      return;
    }

    // ==========================================================
    // GET USER CONTEXT
    //
    // 1 READ
    // ==========================================================

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

    final userData =
        userSnapshot.data();

    if (userData == null) {
      throw Exception(
        'User profile is empty.',
      );
    }

    final branchCode =
        userData['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (branchCode == null ||
        branchCode.isEmpty) {
      throw Exception(
        'Branch setup is incomplete.',
      );
    }

    // ==========================================================
    // VEHICLE REFERENCE
    // ==========================================================

    final vehicleRef =
        _firestore
            .collection('vehicles')
            .doc(vehicleId.trim());

    // ==========================================================
    // GET VEHICLE
    //
    // 1 READ
    // ==========================================================

    final vehicleSnapshot =
        await vehicleRef.get();

    if (!vehicleSnapshot.exists) {
      throw Exception(
        'Vehicle not found.',
      );
    }

    final vehicleData =
        vehicleSnapshot.data();

    if (vehicleData == null) {
      throw Exception(
        'Vehicle data not found.',
      );
    }

    // ==========================================================
    // BRANCH SECURITY CHECK
    // ==========================================================

    final vehicleBranchCode =
        vehicleData['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (vehicleBranchCode !=
        branchCode) {
      throw Exception(
        'You cannot modify a vehicle from another branch.',
      );
    }

    // ==========================================================
    // ALLOWED FIELDS
    // ==========================================================

    const allowedFields = {
      'registrationNumber',
      'make',
      'model',
      'variant',
      'vehicleType',
      'fuelType',
      'transmission',
      'year',
      'color',
      'currentKm',
      'dailyRate',
      'weeklyRate',
      'monthlyRate',
      'securityDeposit',
      'imageUrl',
      'isActive',
    };

    final safeUpdates =
        <String, dynamic>{};

    for (final entry
        in updates.entries) {
      if (allowedFields.contains(
        entry.key,
      )) {
        safeUpdates[
                entry.key] =
            entry.value;
      }
    }

    if (safeUpdates.isEmpty) {
      return;
    }

    // ==========================================================
    // NORMALIZE COMMON FIELDS
    // ==========================================================

    if (safeUpdates
        .containsKey(
      'registrationNumber',
    )) {
      final registration =
          safeUpdates[
                  'registrationNumber']
              ?.toString()
              .trim()
              .toUpperCase();

      if (registration == null ||
          registration.isEmpty) {
        throw Exception(
          'Registration number cannot be empty.',
        );
      }

      safeUpdates[
              'registrationNumber'] =
          registration;
    }

    if (safeUpdates
        .containsKey(
      'make',
    )) {
      safeUpdates['make'] =
          safeUpdates['make']
              ?.toString()
              .trim();
    }

    if (safeUpdates
        .containsKey(
      'model',
    )) {
      safeUpdates['model'] =
          safeUpdates['model']
              ?.toString()
              .trim();
    }

    if (safeUpdates
        .containsKey(
      'variant',
    )) {
      safeUpdates['variant'] =
          safeUpdates['variant']
              ?.toString()
              .trim();
    }

    if (safeUpdates
        .containsKey(
      'color',
    )) {
      safeUpdates['color'] =
          safeUpdates['color']
              ?.toString()
              .trim();
    }

    if (safeUpdates
        .containsKey(
      'vehicleType',
    )) {
      safeUpdates[
              'vehicleType'] =
          safeUpdates['vehicleType']
              ?.toString()
              .trim()
              .toLowerCase();
    }

    if (safeUpdates
        .containsKey(
      'fuelType',
    )) {
      safeUpdates['fuelType'] =
          safeUpdates['fuelType']
              ?.toString()
              .trim()
              .toLowerCase();
    }

    if (safeUpdates
        .containsKey(
      'transmission',
    )) {
      safeUpdates[
              'transmission'] =
          safeUpdates['transmission']
              ?.toString()
              .trim()
              .toLowerCase();
    }

    // ==========================================================
    // VALIDATE NUMBERS
    // ==========================================================

    if (safeUpdates
        .containsKey(
      'currentKm',
    )) {
      final km =
          _toInt(
        safeUpdates[
            'currentKm'],
      );

      if (km < 0) {
        throw Exception(
          'Current KM cannot be negative.',
        );
      }

      safeUpdates[
              'currentKm'] =
          km;
    }

    if (safeUpdates
        .containsKey(
      'year',
    )) {
      final year =
          _toInt(
        safeUpdates['year'],
      );

      if (year < 1900 ||
          year >
              DateTime.now()
                      .year +
                  1) {
        throw Exception(
          'Invalid vehicle year.',
        );
      }

      safeUpdates['year'] =
          year;
    }

    if (safeUpdates
        .containsKey(
      'dailyRate',
    )) {
      final value =
          _toDouble(
        safeUpdates[
            'dailyRate'],
      );

      if (value <= 0) {
        throw Exception(
          'Daily rental rate must be greater than zero.',
        );
      }

      safeUpdates[
              'dailyRate'] =
          value;
    }

    if (safeUpdates
        .containsKey(
      'weeklyRate',
    )) {
      final value =
          _toDouble(
        safeUpdates[
            'weeklyRate'],
      );

      if (value < 0) {
        throw Exception(
          'Weekly rental rate cannot be negative.',
        );
      }

      safeUpdates[
              'weeklyRate'] =
          value;
    }

    if (safeUpdates
        .containsKey(
      'monthlyRate',
    )) {
      final value =
          _toDouble(
        safeUpdates[
            'monthlyRate'],
      );

      if (value < 0) {
        throw Exception(
          'Monthly rental rate cannot be negative.',
        );
      }

      safeUpdates[
              'monthlyRate'] =
          value;
    }

    if (safeUpdates
        .containsKey(
      'securityDeposit',
    )) {
      final value =
          _toDouble(
        safeUpdates[
            'securityDeposit'],
      );

      if (value < 0) {
        throw Exception(
          'Security deposit cannot be negative.',
        );
      }

      safeUpdates[
              'securityDeposit'] =
          value;
    }

    // ==========================================================
    // REGISTRATION CHANGE
    //
    // If registration number changes, maintain the
    // vehicleKeys index.
    // ==========================================================

    final oldRegistration =
        vehicleData[
                'registrationNumber']
            ?.toString()
            .trim()
            .toUpperCase();

    final newRegistration =
        safeUpdates
            .containsKey(
      'registrationNumber',
    )
            ? safeUpdates[
                    'registrationNumber']
                ?.toString()
                .trim()
                .toUpperCase()
            : oldRegistration;

    final registrationChanged =
        oldRegistration !=
            null &&
        newRegistration !=
            null &&
        oldRegistration !=
            newRegistration;

    // ==========================================================
    // SIMPLE UPDATE
    // ==========================================================

    if (!registrationChanged) {
      safeUpdates['updatedAt'] =
          FieldValue.serverTimestamp();

      await vehicleRef.update(
        safeUpdates,
      );

      return;
    }

    // ==========================================================
    // REGISTRATION CHANGE TRANSACTION
    // ==========================================================

    final oldKey =
        '${branchCode}_${oldRegistration}'
            .replaceAll(
              '/',
              '_',
            );

    final newKey =
        '${branchCode}_${newRegistration}'
            .replaceAll(
              '/',
              '_',
            );

    final oldKeyRef =
        _firestore
            .collection('vehicleKeys')
            .doc(oldKey);

    final newKeyRef =
        _firestore
            .collection('vehicleKeys')
            .doc(newKey);

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ NEW REGISTRATION KEY
        // --------------------------------------------------------

        final newKeySnapshot =
            await transaction.get(
          newKeyRef,
        );

        if (newKeySnapshot.exists) {
          throw Exception(
            'Another vehicle already uses this registration number in this branch.',
          );
        }

        // --------------------------------------------------------
        // UPDATE VEHICLE
        // --------------------------------------------------------

        safeUpdates['updatedAt'] =
            FieldValue.serverTimestamp();

        transaction.update(
          vehicleRef,
          safeUpdates,
        );

        // --------------------------------------------------------
        // DELETE OLD KEY
        // --------------------------------------------------------

        transaction.delete(
          oldKeyRef,
        );

        // --------------------------------------------------------
        // CREATE NEW KEY
        // --------------------------------------------------------

        transaction.set(
          newKeyRef,
          {
            'vehicleId':
                vehicleId,

            'businessId':
                vehicleData[
                    'businessId'],

            'branchCode':
                branchCode,

            'registrationNumber':
                newRegistration,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // CHANGE VEHICLE STATUS
  //
  // ATOMIC:
  //
  // vehicle status
  // +
  // dashboard counters
  //
  // are changed together.
  // ============================================================

  Future<void> updateVehicleStatus({
    required String vehicleId,
    required VehicleStatus status,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    // ==========================================================
    // GET USER BRANCH
    //
    // 1 READ
    // ==========================================================

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

    final userData =
        userSnapshot.data();

    if (userData == null) {
      throw Exception(
        'User profile is empty.',
      );
    }

    final branchCode =
        userData['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (branchCode == null ||
        branchCode.isEmpty) {
      throw Exception(
        'Branch setup is incomplete.',
      );
    }

    // ==========================================================
    // REFERENCES
    // ==========================================================

    final vehicleRef =
        _firestore
            .collection('vehicles')
            .doc(
              vehicleId.trim(),
            );

    final statsRef =
        _firestore
            .collection('dashboardStats')
            .doc(branchCode);

    // ==========================================================
    // TRANSACTION
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // ALL READS FIRST
        // --------------------------------------------------------

        final vehicleSnapshot =
            await transaction.get(
          vehicleRef,
        );

        if (!vehicleSnapshot.exists) {
          throw Exception(
            'Vehicle not found.',
          );
        }

        final vehicleData =
            vehicleSnapshot.data();

        if (vehicleData == null) {
          throw Exception(
            'Vehicle data not found.',
          );
        }

        final vehicleBranchCode =
            vehicleData[
                    'branchCode']
                ?.toString()
                .trim()
                .toUpperCase();

        if (vehicleBranchCode !=
            branchCode) {
          throw Exception(
            'You cannot modify a vehicle from another branch.',
          );
        }

        // --------------------------------------------------------
        // CURRENT STATUS
        // --------------------------------------------------------

        final oldStatus =
            VehicleModel
                .statusFromString(
          vehicleData[
                  'status']
              ?.toString(),
        );

        if (oldStatus == status) {
          return;
        }

        // --------------------------------------------------------
        // DASHBOARD STATS
        // --------------------------------------------------------

        final statsSnapshot =
            await transaction.get(
          statsRef,
        );

        if (!statsSnapshot.exists) {
          throw Exception(
            'Dashboard statistics are not initialized for this branch.',
          );
        }

        // ========================================================
        // CALCULATE COUNTER DELTAS
        // ========================================================

        int availableDelta = 0;
        int reservedDelta = 0;
        int rentedDelta = 0;
        int maintenanceDelta = 0;

        // --------------------------------------------------------
        // REMOVE OLD STATUS
        // --------------------------------------------------------

        switch (oldStatus) {
          case VehicleStatus.available:
            availableDelta--;
            break;

          case VehicleStatus.reserved:
            reservedDelta--;
            break;

          case VehicleStatus.rented:
            rentedDelta--;
            break;

          case VehicleStatus.maintenance:
            maintenanceDelta--;
            break;

          case VehicleStatus.inactive:
            break;
        }

        // --------------------------------------------------------
        // ADD NEW STATUS
        // --------------------------------------------------------

        switch (status) {
          case VehicleStatus.available:
            availableDelta++;
            break;

          case VehicleStatus.reserved:
            reservedDelta++;
            break;

          case VehicleStatus.rented:
            rentedDelta++;
            break;

          case VehicleStatus.maintenance:
            maintenanceDelta++;
            break;

          case VehicleStatus.inactive:
            break;
        }

        // ========================================================
        // UPDATE VEHICLE
        // ========================================================

        transaction.update(
          vehicleRef,
          {
            'status':
                VehicleModel
                    .statusToString(
              status,
            ),

            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        // ========================================================
        // UPDATE DASHBOARD
        // ========================================================

        final statsUpdate =
            <String, dynamic>{
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        };

        if (availableDelta != 0) {
          statsUpdate[
                  'availableVehicles'] =
              FieldValue.increment(
            availableDelta,
          );
        }

        if (reservedDelta != 0) {
          statsUpdate[
                  'reservedVehicles'] =
              FieldValue.increment(
            reservedDelta,
          );
        }

        if (rentedDelta != 0) {
          statsUpdate[
                  'rentedVehicles'] =
              FieldValue.increment(
            rentedDelta,
          );
        }

        if (maintenanceDelta !=
            0) {
          statsUpdate[
                  'maintenanceVehicles'] =
              FieldValue.increment(
            maintenanceDelta,
          );
        }

        transaction.update(
          statsRef,
          statsUpdate,
        );
      },
    );
  }

  // ============================================================
  // DEACTIVATE VEHICLE
  //
  // SOFT DELETE
  //
  // Rental history remains safe.
  // ============================================================

  Future<void> deactivateVehicle(
    String vehicleId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    // ==========================================================
    // USER BRANCH
    // ==========================================================

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

    final userData =
        userSnapshot.data();

    final branchCode =
        userData?['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (branchCode == null ||
        branchCode.isEmpty) {
      throw Exception(
        'Branch setup is incomplete.',
      );
    }

    // ==========================================================
    // VEHICLE
    // ==========================================================

    final vehicleRef =
        _firestore
            .collection('vehicles')
            .doc(
              vehicleId.trim(),
            );

    // ==========================================================
    // STATS
    // ==========================================================

    final statsRef =
        _firestore
            .collection('dashboardStats')
            .doc(branchCode);

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ VEHICLE
        // --------------------------------------------------------

        final vehicleSnapshot =
            await transaction.get(
          vehicleRef,
        );

        if (!vehicleSnapshot.exists) {
          throw Exception(
            'Vehicle not found.',
          );
        }

        final vehicleData =
            vehicleSnapshot.data();

        if (vehicleData == null) {
          throw Exception(
            'Vehicle data not found.',
          );
        }

        // --------------------------------------------------------
        // BRANCH CHECK
        // --------------------------------------------------------

        final vehicleBranchCode =
            vehicleData[
                    'branchCode']
                ?.toString()
                .trim()
                .toUpperCase();

        if (vehicleBranchCode !=
            branchCode) {
          throw Exception(
            'You cannot deactivate a vehicle from another branch.',
          );
        }

        // --------------------------------------------------------
        // CHECK ACTIVE
        // --------------------------------------------------------

        final isActive =
            vehicleData[
                    'isActive'] ==
                true;

        if (!isActive) {
          return;
        }

        // --------------------------------------------------------
        // READ STATS
        // --------------------------------------------------------

        final statsSnapshot =
            await transaction.get(
          statsRef,
        );

        if (!statsSnapshot.exists) {
          throw Exception(
            'Dashboard statistics are not initialized for this branch.',
          );
        }

        // --------------------------------------------------------
        // CURRENT STATUS
        // --------------------------------------------------------

        final currentStatus =
            VehicleModel
                .statusFromString(
          vehicleData[
                  'status']
              ?.toString(),
        );

        // --------------------------------------------------------
        // UPDATE VEHICLE
        // --------------------------------------------------------

        transaction.update(
          vehicleRef,
          {
            'isActive':
                false,

            'status':
                VehicleModel
                    .statusToString(
              VehicleStatus.inactive,
            ),

            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // UPDATE DASHBOARD
        // --------------------------------------------------------

        final statsUpdate =
            <String, dynamic>{
          'totalVehicles':
              FieldValue.increment(-1),

          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        };

        switch (currentStatus) {
          case VehicleStatus.available:
            statsUpdate[
                    'availableVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.reserved:
            statsUpdate[
                    'reservedVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.rented:
            statsUpdate[
                    'rentedVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.maintenance:
            statsUpdate[
                    'maintenanceVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.inactive:
            break;
        }

        transaction.update(
          statsRef,
          statsUpdate,
        );
      },
    );
  }

  // ============================================================
  // REACTIVATE VEHICLE
  //
  // Inactive → Available
  // ============================================================

  Future<void> reactivateVehicle(
    String vehicleId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    // ==========================================================
    // USER BRANCH
    // ==========================================================

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

    final userData =
        userSnapshot.data();

    final branchCode =
        userData?['branchCode']
            ?.toString()
            .trim()
            .toUpperCase();

    if (branchCode == null ||
        branchCode.isEmpty) {
      throw Exception(
        'Branch setup is incomplete.',
      );
    }

    // ==========================================================
    // REFERENCES
    // ==========================================================

    final vehicleRef =
        _firestore
            .collection('vehicles')
            .doc(
              vehicleId.trim(),
            );

    final statsRef =
        _firestore
            .collection('dashboardStats')
            .doc(branchCode);

    // ==========================================================
    // TRANSACTION
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ VEHICLE
        // --------------------------------------------------------

        final vehicleSnapshot =
            await transaction.get(
          vehicleRef,
        );

        if (!vehicleSnapshot.exists) {
          throw Exception(
            'Vehicle not found.',
          );
        }

        final vehicleData =
            vehicleSnapshot.data();

        if (vehicleData == null) {
          throw Exception(
            'Vehicle data not found.',
          );
        }

        final vehicleBranchCode =
            vehicleData[
                    'branchCode']
                ?.toString()
                .trim()
                .toUpperCase();

        if (vehicleBranchCode !=
            branchCode) {
          throw Exception(
            'You cannot reactivate a vehicle from another branch.',
          );
        }

        final currentStatus =
            VehicleModel
                .statusFromString(
          vehicleData[
                  'status']
              ?.toString(),
        );

        final isActive =
            vehicleData[
                    'isActive'] ==
                true;

        if (isActive &&
            currentStatus ==
                VehicleStatus
                    .available) {
          return;
        }

        // --------------------------------------------------------
        // READ STATS
        // --------------------------------------------------------

        final statsSnapshot =
            await transaction.get(
          statsRef,
        );

        if (!statsSnapshot.exists) {
          throw Exception(
            'Dashboard statistics are not initialized for this branch.',
          );
        }

        // --------------------------------------------------------
        // VEHICLE
        // --------------------------------------------------------

        transaction.update(
          vehicleRef,
          {
            'isActive':
                true,

            'status':
                VehicleModel
                    .statusToString(
              VehicleStatus.available,
            ),

            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // DASHBOARD
        // --------------------------------------------------------

        final statsUpdate =
            <String, dynamic>{
          'totalVehicles':
              FieldValue.increment(1),

          'availableVehicles':
              FieldValue.increment(1),

          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        };

        // If the vehicle was somehow still counted
        // under another active status, remove it.
        switch (currentStatus) {
          case VehicleStatus.reserved:
            statsUpdate[
                    'reservedVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.rented:
            statsUpdate[
                    'rentedVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.maintenance:
            statsUpdate[
                    'maintenanceVehicles'] =
                FieldValue.increment(-1);
            break;

          case VehicleStatus.available:
            if (isActive) {
              // Already counted.
              statsUpdate[
                      'availableVehicles'] =
                  FieldValue.increment(0);
            }
            break;

          case VehicleStatus.inactive:
            break;
        }

        transaction.update(
          statsRef,
          statsUpdate,
        );
      },
    );
  }

  // ============================================================
  // HELPER: INT
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

  // ============================================================
  // HELPER: DOUBLE
  // ============================================================

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
}

