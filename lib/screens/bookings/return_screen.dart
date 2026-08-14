import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';

import 'package:car_rental/models/booking_model.dart';
import 'package:car_rental/services/booking_service.dart';
import '../../app/theme.dart';

class ReturnScreen extends StatefulWidget {
  final BookingModel booking;

  const ReturnScreen({
    super.key,
    required this.booking,
  });

  @override
  State<ReturnScreen> createState() =>
      _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final BookingService _bookingService =
      BookingService.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late BookingModel _booking;

  final TextEditingController _endingKmController =
      TextEditingController();

  final TextEditingController _extraKmController =
      TextEditingController();

  final TextEditingController _fuelChargeController =
      TextEditingController();

  final TextEditingController _lateReturnController =
      TextEditingController();

  final TextEditingController _damageController =
      TextEditingController();

  final TextEditingController _otherChargesController =
      TextEditingController();

  final TextEditingController _paidAmountController =
      TextEditingController();

  final TextEditingController _internalNotesController =
      TextEditingController();

  FuelLevel? _fuelAtReturn;

bool _isSaving = false;

final ImagePicker _imagePicker =
    ImagePicker();

final Map<String, File?> _returnImages = {
  'front': null,
  'rear': null,
  'left': null,
  'right': null,
  'interior': null,
  'dashboard': null,
  'extra': null,
};

final Map<String, String> _returnImageUrls = {};

String? _uploadingPhotoType;

String _savingMessage =
    'Complete Booking';

  @override
  void initState() {
    super.initState();

    _booking = widget.booking;

    _endingKmController.text =
        _booking.endingKm?.toString() ?? '';

    _fuelAtReturn =
        _booking.fuelAtReturn;
        for (final entry
    in _booking.returnImages.entries) {
  if (entry.value.isNotEmpty) {
    _returnImageUrls[entry.key] =
        entry.value;
  }
}

    _extraKmController.text =
        _formatInput(_booking.extraKmCharge);

    _fuelChargeController.text =
        _formatInput(_booking.fuelCharge);

    _lateReturnController.text =
        _formatInput(_booking.lateReturnCharge);

    _damageController.text =
        _formatInput(_booking.damageCharge);

    _otherChargesController.text =
        _formatInput(_booking.otherCharges);

    _paidAmountController.text =
        _formatInput(_booking.paidAmount);

    _internalNotesController.text =
        _booking.internalNotes ?? '';

    _endingKmController.addListener(_recalculate);
    _extraKmController.addListener(_recalculate);
    _fuelChargeController.addListener(_recalculate);
    _lateReturnController.addListener(_recalculate);
    _damageController.addListener(_recalculate);
    _otherChargesController.addListener(_recalculate);
    _paidAmountController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _endingKmController.dispose();
    _extraKmController.dispose();
    _fuelChargeController.dispose();
    _lateReturnController.dispose();
    _damageController.dispose();
    _otherChargesController.dispose();
    _paidAmountController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

  // ============================================================
  // STATUS
  // ============================================================

bool get _isActive =>
    _booking.status == BookingStatus.active;

bool get _isReturning =>
    _booking.status == BookingStatus.returning;

bool get _canComplete =>
    _isReturning;

  // ============================================================
  // PARSING
  // ============================================================

  String _formatInput(double value) {
    if (value == 0) return '0';

    return value
        .toStringAsFixed(2)
        .replaceFirst(
          RegExp(r'\.?0+$'),
          '',
        );
  }

  double _number(
    String value,
  ) {
    return double.tryParse(
          value.trim(),
        ) ??
        0;
  }

  int? _endingKm() {
    return int.tryParse(
      _endingKmController.text.trim(),
    );
  }

  // ============================================================
  // CHARGE CALCULATION
  // ============================================================

  double get _extraKmCharge =>
      _number(
        _extraKmController.text,
      );

  double get _fuelCharge =>
      _number(
        _fuelChargeController.text,
      );

  double get _lateReturnCharge =>
      _number(
        _lateReturnController.text,
      );

  double get _damageCharge =>
      _number(
        _damageController.text,
      );

  double get _otherCharges =>
      _number(
        _otherChargesController.text,
      );

  double get _paidAmount =>
      _number(
        _paidAmountController.text,
      );

  // ReturnScreen
double get _finalTotal {
  return _booking.totalAmount +
      _extraKmCharge +
      _fuelCharge +
      _lateReturnCharge +
      _damageCharge +
      _otherCharges;
}

  double get _pendingAmount {
    final pending =
        _finalTotal - _paidAmount;

    return pending < 0 ? 0 : pending;
  }

  PaymentStatus get _paymentStatus {
    if (_paidAmount <= 0) {
      return PaymentStatus.unpaid;
    }

    if (_paidAmount >= _finalTotal) {
      return PaymentStatus.paid;
    }

    return PaymentStatus.partiallyPaid;
  }

  void _recalculate() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // START RETURN PROCESSING
  //
  // completeBooking() expects BookingStatus.returning.
  // The return screen therefore moves Return Pending -> Returning
  // before the final completion step.
  // ============================================================

 Future<void> _startReturnProcessing() async {
  if (_isSaving) return;

  setState(() {
    _isSaving = true;
  });

  try {
    final ref = _firestore
        .collection('bookings')
        .doc(_booking.id);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw Exception('Booking not found.');
    }

    final current =
        BookingModel.fromFirestore(snapshot);

    // Return can start ONLY from ACTIVE.
    if (current.status != BookingStatus.active) {
      setState(() {
        _booking = current;
      });

      throw Exception(
        'Return can only be started for an active booking.',
      );
    }

    final now = DateTime.now();

    await ref.update({
      'status': BookingStatus.returning.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    if (!mounted) return;

    setState(() {
      _booking = current.copyWith(
        status: BookingStatus.returning,
        updatedAt: now,
      );
    });

    _showMessage(
      'Return inspection started.',
    );
  } catch (e) {
    if (!mounted) return;

    _showError(
      _cleanError(e.toString()),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
Future<void> _pickReturnImage(
  String type,
) async {
  if (_isSaving) return;

  final source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor:
        AppColors.surface,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Add Return Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                ),
                title: const Text(
                  'Take Photo',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.camera,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                ),
                title: const Text(
                  'Choose from Gallery',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return;

  try {
    final picked =
        await _imagePicker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (picked == null) return;

    setState(() {
      _returnImages[type] =
          File(picked.path);
    });
  } catch (e) {
    if (!mounted) return;

    _showError(
      'Unable to select image.',
    );
  }
}
Future<Uint8List> _optimizeImage(
  File file,
) async {
  final bytes =
      await file.readAsBytes();

  final decoded =
      img.decodeImage(bytes);

  if (decoded == null) {
    throw Exception(
      'Unable to process image.',
    );
  }

  final oriented =
      img.bakeOrientation(decoded);

  const maxDimension = 1600;

  img.Image resized =
      oriented;

  if (oriented.width >
          maxDimension ||
      oriented.height >
          maxDimension) {
    resized = img.copyResize(
      oriented,
      width:
          oriented.width >=
                  oriented.height
              ? maxDimension
              : null,
      height:
          oriented.height >
                  oriented.width
              ? maxDimension
              : null,
      interpolation:
          img.Interpolation.average,
    );
  }

  int quality = 85;

  Uint8List output =
      Uint8List.fromList(
    img.encodeJpg(
      resized,
      quality: quality,
    ),
  );

  while (output.length >
          500 * 1024 &&
      quality > 45) {
    quality -= 5;

    output =
        Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: quality,
      ),
    );
  }

  return output;
}
Future<String> _uploadReturnImage(
  String type,
  File file,
) async {
  final optimized =
      await _optimizeImage(file);

  final storageRef =
      FirebaseStorage.instance
          .ref()
          .child(
            'bookings/${_booking.id}/return/$type.jpg',
          );

  await storageRef.putData(
    optimized,
    SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl:
          'public,max-age=31536000',
    ),
  );

  return storageRef.getDownloadURL();
}
Future<void> _uploadAllReturnImages() async {
  for (final entry
      in _returnImages.entries) {
    final type = entry.key;
    final file = entry.value;

    if (file == null) continue;

    if (mounted) {
      setState(() {
        _uploadingPhotoType =
            type;

        _savingMessage =
            'Uploading ${_photoTitle(type)}...';
      });
    }

    final url =
        await _uploadReturnImage(
      type,
      file,
    );

    _returnImageUrls[type] =
        url;
  }

  if (mounted) {
    setState(() {
      _uploadingPhotoType = null;
    });
  }
}
String _photoTitle(
  String type,
) {
  switch (type) {
    case 'front':
      return 'front photo';

    case 'rear':
      return 'rear photo';

    case 'left':
      return 'left-side photo';

    case 'right':
      return 'right-side photo';

    case 'interior':
      return 'interior photo';

    case 'dashboard':
      return 'dashboard photo';

    case 'extra':
      return 'extra photo';

    default:
      return 'vehicle photo';
  }
}

  // ============================================================
  // COMPLETE BOOKING
  // ============================================================

Future<void> _completeReturn() async {
  if (_isSaving) return;

  FocusScope.of(context).unfocus();

  // ==========================================================
  // ENDING KM
  // ==========================================================

  final endingKm = _endingKm();

  if (endingKm == null) {
    _showError(
      'Enter a valid ending KM.',
    );
    return;
  }

  // ==========================================================
  // STARTING KM
  // ==========================================================

  final startingKm =
      _booking.startingKm;

  if (startingKm == null) {
    _showError(
      'Starting KM has not been recorded for this booking.',
    );
    return;
  }

  if (endingKm < startingKm) {
    _showError(
      'Ending KM cannot be less than starting KM.',
    );
    return;
  }

  // ==========================================================
  // FUEL
  // ==========================================================

  if (_fuelAtReturn == null) {
    _showError(
      'Select the fuel level at return.',
    );
    return;
  }

  // ==========================================================
  // REQUIRED RETURN PHOTOS
  // ==========================================================

 

  // ==========================================================
  // PAYMENT
  // ==========================================================

  if (_paidAmount < 0) {
    _showError(
      'Paid amount cannot be negative.',
    );
    return;
  }

  if (_paidAmount > _finalTotal) {
    _showError(
      'Paid amount cannot be greater than the final total.',
    );
    return;
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  setState(() {
    _isSaving = true;
    _savingMessage =
        'Preparing return...';
  });

  try {
    // --------------------------------------------------------
    // OPTIMIZE + UPLOAD RETURN IMAGES
    // --------------------------------------------------------

    await _uploadAllReturnImages();

    if (!mounted) return;

    setState(() {
      _savingMessage =
          'Completing booking...';
    });

    // --------------------------------------------------------
    // COMPLETE BOOKING
    // --------------------------------------------------------

    final updated =
        await _bookingService.completeBooking(
      bookingId:
          _booking.id,

      endingKm:
          endingKm,

      fuelAtReturn:
          _fuelAtReturn!,

      // Return charges
      extraKmCharge:
          _extraKmCharge,

      fuelCharge:
          _fuelCharge,

      lateReturnCharge:
          _lateReturnCharge,

      damageCharge:
          _damageCharge,

      otherCharges:
          _otherCharges,

      // Payment
      paidAmount:
          _paidAmount,

      // Notes
      internalNotes:
          _internalNotesController
              .text
              .trim()
              .isEmpty
              ? null
              : _internalNotesController
                  .text
                  .trim(),

      // RETURN IMAGES
      returnImages:
          _returnImageUrls,
    );

    if (!mounted) return;

    setState(() {
      _booking = updated;
      _isSaving = false;
      _savingMessage =
          'Complete Booking';
    });

    _showMessage(
      'Booking completed successfully.',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pop(
      _booking,
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _uploadingPhotoType = null;
      _savingMessage =
          'Complete Booking';
    });

    _showError(
      _cleanError(
        e.toString(),
      ),
    );
  }
}

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(
    String error,
  ) {
    return error
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  String _money(
    double value,
  ) {
    return NumberFormat(
      '#,##0.##',
    ).format(value);
  }

  String _fuelLabel(
    FuelLevel? fuel,
  ) {
    if (fuel == null) {
      return 'Not selected';
    }

    switch (fuel) {
      case FuelLevel.empty:
        return 'Empty';

      case FuelLevel.quarter:
        return '¼ Tank';

      case FuelLevel.half:
        return '½ Tank';

      case FuelLevel.threeQuarter:
        return '¾ Tank';

      case FuelLevel.full:
        return 'Full';
    }
  }

  IconData _fuelIcon(
    FuelLevel fuel,
  ) {
    switch (fuel) {
      case FuelLevel.empty:
        return Icons.local_gas_station_outlined;

      case FuelLevel.quarter:
        return Icons.battery_1_bar_rounded;

      case FuelLevel.half:
        return Icons.battery_4_bar_rounded;

      case FuelLevel.threeQuarter:
        return Icons.battery_5_bar_rounded;

      case FuelLevel.full:
        return Icons.battery_full_rounded;
    }
  }

  String _paymentLabel(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Unpaid';

      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';

      case PaymentStatus.paid:
        return 'Paid';

      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Color _paymentColor(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.unpaid:
        return AppColors.danger;

      case PaymentStatus.partiallyPaid:
        return AppColors.warning;

      case PaymentStatus.paid:
        return AppColors.success;

      case PaymentStatus.refunded:
        return AppColors.primary;
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          content:
              Text(message),
        ),
      );
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          backgroundColor:
              AppColors.danger,
          content:
              Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final isEditable =
        _isReturning;

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar:
          AppBar(
        elevation: 0,
        backgroundColor:
            AppColors.background,
        surfaceTintColor:
            Colors.transparent,
        titleSpacing: 0,
        leading:
            IconButton(
          icon:
              const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed:
              () =>
                  Navigator.of(context)
                      .pop(),
        ),
        title:
            const Text(
          'Vehicle Return',
          style:
              TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
            color:
                AppColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar:
          _buildBottomAction(
            isEditable:
                isEditable,
          ),
      body:
          SafeArea(
        child:
            ListView(
          padding:
              const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            120,
          ),
          children: [
            _buildHeader(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildCustomerVehicle(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildSchedule(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildOdometer(
              enabled:
                  isEditable,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildFuel(
              enabled:
                  isEditable,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildCharges(
              enabled:
                  isEditable,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildPaymentSummary(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildReturnPhotos(
  enabled:
      isEditable,
),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildNotes(
              enabled:
                  isEditable,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final statusColor =
    _isReturning
        ? AppColors.primary
        : _isActive
            ? AppColors.success
            : AppColors.textSecondary;

final statusText =
    _isReturning
        ? 'Returning'
        : _isActive
            ? 'Active'
            : 'Return Unavailable';

    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOKING',
                      style:
                          TextStyle(
                        fontSize: 9,
                        letterSpacing:
                            0.8,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      _booking.bookingNumber,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      statusColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child:
                    Text(
                  statusText,
                  style:
                      TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          const Divider(
            height: 1,
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          Text(
  _isReturning
      ? 'Complete the final vehicle inspection and payment before closing this rental.'
      : _isActive
          ? 'Start the return inspection when the vehicle is physically received.'
          : 'This booking is not available for return.',
            style:
                const TextStyle(
              fontSize: 10,
              height: 1.45,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER / VEHICLE
  // ============================================================

  Widget _buildCustomerVehicle() {
    return _sectionCard(
      title:
          'Customer & Vehicle',
      icon:
          Icons.directions_car_rounded,
      child:
          Column(
        children: [
          _infoRow(
            icon:
                Icons.person_outline_rounded,
            label:
                'Customer',
            value:
                _booking.customerName,
          ),
          const SizedBox(
            height: 12,
          ),
          _infoRow(
            icon:
                Icons.phone_outlined,
            label:
                'Phone',
            value:
                _booking.customerPhone,
          ),
          const SizedBox(
            height: 12,
          ),
          _infoRow(
            icon:
                Icons.directions_car_outlined,
            label:
                'Vehicle',
            value:
                _booking.vehicleName,
          ),
          const SizedBox(
            height: 12,
          ),
          _infoRow(
            icon:
                Icons.confirmation_number_outlined,
            label:
                'Registration',
            value:
                _booking.vehicleRegistrationNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    return _sectionCard(
      title:
          'Rental Schedule',
      icon:
          Icons.schedule_rounded,
      child:
          Row(
        children: [
          Expanded(
            child:
                _dateBox(
              title:
                  'Pickup',
              date:
                  _booking.pickupDateTime,
              icon:
                  Icons.login_rounded,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                _dateBox(
              title:
                  'Return',
              date:
                  _booking.returnDateTime,
              icon:
                  Icons.logout_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required String title,
    required DateTime date,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 8,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.textSecondary,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            DateFormat(
              'dd MMM yyyy',
            ).format(date),
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            DateFormat(
              'hh:mm a',
            ).format(date),
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ODOMETER
  // ============================================================

  Widget _buildOdometer({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Odometer',
      icon:
          Icons.speed_rounded,
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextField(
            controller:
                _endingKmController,
            enabled:
                enabled,
            keyboardType:
                TextInputType.number,
            decoration:
                InputDecoration(
              labelText:
                  'Ending KM',
              hintText:
                  'Enter final odometer reading',
              suffixText:
                  'KM',
              prefixIcon:
                  const Icon(
                Icons.speed_rounded,
              ),
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          _smallValue(
            'Starting KM',
            '${_booking.startingKm} KM',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FUEL
  // ============================================================

  Widget _buildFuel({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Fuel at Return',
      icon:
          Icons.local_gas_station_outlined,
      child:
          Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            FuelLevel.values.map(
          (fuel) {
            final selected =
                _fuelAtReturn ==
                    fuel;

            return ChoiceChip(
              selected:
                  selected,
              onSelected:
                  enabled
                      ? (_) {
                          setState(() {
                            _fuelAtReturn =
                                fuel;
                          });
                        }
                      : null,
              avatar:
                  Icon(
                _fuelIcon(fuel),
                size: 16,
                color:
                    selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
              label:
                  Text(
                _fuelLabel(fuel),
              ),
              labelStyle:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
                color:
                    selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // CHARGES
  // ============================================================

  Widget _buildCharges({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Return Charges',
      icon:
          Icons.receipt_long_outlined,
      child:
          Column(
        children: [
          _chargeField(
            controller:
                _extraKmController,
            label:
                'Extra KM Charge',
            icon:
                Icons.add_road_rounded,
            enabled:
                enabled,
          ),
          const SizedBox(
            height: 10,
          ),
          _chargeField(
            controller:
                _fuelChargeController,
            label:
                'Fuel Charge',
            icon:
                Icons.local_gas_station_outlined,
            enabled:
                enabled,
          ),
          const SizedBox(
            height: 10,
          ),
          _chargeField(
            controller:
                _lateReturnController,
            label:
                'Late Return Charge',
            icon:
                Icons.schedule_rounded,
            enabled:
                enabled,
          ),
          const SizedBox(
            height: 10,
          ),
          _chargeField(
            controller:
                _damageController,
            label:
                'Damage Charge',
            icon:
                Icons.build_outlined,
            enabled:
                enabled,
          ),
          const SizedBox(
            height: 10,
          ),
          _chargeField(
            controller:
                _otherChargesController,
            label:
                'Other Charges',
            icon:
                Icons.more_horiz_rounded,
            enabled:
                enabled,
          ),
          const SizedBox(
            height: 16,
          ),
          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
              border:
                  Border.all(
                color:
                    AppColors.border,
              ),
            ),
            child:
                Column(
              children: [
                _summaryRow(
                  'Base Rental',
                  _money(
                    _booking.baseRentalAmount,
                  ),
                ),
                _summaryRow(
                  'Security Deposit',
                  _money(
                    _booking.securityDeposit,
                  ),
                ),
                _summaryRow(
                  'Discount',
                  '- ${_money(_booking.discount)}',
                ),
                _summaryRow(
                  'Tax',
                  _money(
                    _booking.tax,
                  ),
                ),
                const Divider(
                  height: 18,
                ),
                _summaryRow(
                  'Final Total',
                  _money(
                    _finalTotal,
                  ),
                  strong:
                      true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return TextField(
      controller:
          controller,
      enabled:
          enabled,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration:
          InputDecoration(
        labelText:
            label,
        prefixIcon:
            Icon(icon),
        prefixText:
            '₹ ',
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentSummary() {
    final paymentColor =
        _paymentColor(
      _paymentStatus,
    );

    return _sectionCard(
      title:
          'Payment',
      icon:
          Icons.payments_outlined,
      child:
          Column(
        children: [
          // _chargeField(
          //   controller:
          //       _paidAmountController,
          //   label:
          //       'Paid Amount',
          //   icon:
          //       Icons.payments_outlined,
          //   enabled:
          //       _isReturning,
          // ),
          // const SizedBox(
          //   height: 14,
          // ),
          _summaryRow(
            'Final Total',
            '₹ ${_money(_finalTotal)}',
            strong:
                true,
          ),
          _summaryRow(
            'Paid',
            '₹ ${_money(_paidAmount)}',
          ),
          _summaryRow(
            'Pending',
            '₹ ${_money(_pendingAmount)}',
            strong:
                _pendingAmount > 0,
          ),
          const SizedBox(
            height: 10,
          ),
          Align(
            alignment:
                Alignment.centerLeft,
            child:
                Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration:
                  BoxDecoration(
                color:
                    paymentColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
              ),
              child:
                  Text(
                _paymentLabel(
                  _paymentStatus,
                ),
                style:
                    TextStyle(
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      paymentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKLIST
  // ============================================================


Widget _buildReturnPhotos({
  required bool enabled,
}) {
  return _sectionCard(
    title:
        'Return Photos',
    icon:
        Icons.camera_alt_outlined,
    child:
        Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Capture the vehicle condition after return. Front, rear, both sides and interior are required.',
          style: TextStyle(
            fontSize: 10,
            height: 1.4,
            color:
                AppColors.textSecondary,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        GridView.count(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            _returnPhotoTile(
              type: 'front',
              title: 'Front',
              icon: Icons
                  .directions_car_filled_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'rear',
              title: 'Rear',
              icon: Icons
                  .directions_car_filled_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'left',
              title: 'Left Side',
              icon: Icons
                  .directions_car_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'right',
              title: 'Right Side',
              icon: Icons
                  .directions_car_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'interior',
              title: 'Interior',
              icon: Icons
                  .airline_seat_recline_normal_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'dashboard',
              title: 'Dashboard',
              icon: Icons
                  .dashboard_rounded,
              enabled: enabled,
            ),

            _returnPhotoTile(
              type: 'extra',
              title: 'Extra',
              icon: Icons
                  .add_a_photo_rounded,
              enabled: enabled,
            ),
          ],
        ),
      ],
    ),
  );
}
Widget _returnPhotoTile({
  required String type,
  required String title,
  required IconData icon,
  required bool enabled,
}) {
  final file =
      _returnImages[type];

  final existingUrl =
      _returnImageUrls[type];

  final hasImage =
      file != null ||
      (existingUrl != null &&
          existingUrl.isNotEmpty);

  final isUploading =
      _uploadingPhotoType == type;

  return GestureDetector(
    onTap: enabled
        ? () => _pickReturnImage(type)
        : null,
    child: Container(
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
        border:
            Border.all(
          color: hasImage
              ? AppColors.primary
                  .withValues(
                  alpha: 0.35,
                )
              : AppColors.border,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: !hasImage
          ? Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color:
                      AppColors.textSecondary,
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Tap to add',
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            )
          : Stack(
              fit:
                  StackFit.expand,
              children: [
                if (file != null)
                  Image.file(
                    file,
                    fit:
                        BoxFit.cover,
                  )
                else
                  Image.network(
                    existingUrl!,
                    fit:
                        BoxFit.cover,
                  ),

                Positioned(
                  left: 8,
                  bottom: 8,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withValues(
                        alpha: 0.65,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                if (isUploading)
                  const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Colors.white,
                    ),
                  ),

                if (enabled &&
                    !isUploading)
                  Positioned(
                    top: 7,
                    right: 7,
                    child:
                        Container(
                      width: 28,
                      height: 28,
                      decoration:
                          const BoxDecoration(
                        color:
                            Colors.white,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color:
                            AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotes({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Internal Notes',
      icon:
          Icons.notes_rounded,
      child:
          TextField(
        controller:
            _internalNotesController,
        enabled:
            enabled,
        minLines:
            3,
        maxLines:
            6,
        decoration:
            const InputDecoration(
          hintText:
              'Add return notes, damage details or payment remarks...',
          alignLabelWithHint:
              true,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

Widget _buildBottomAction({
  required bool isEditable,
}) {
  final bool startProcessing =
      _isActive;

  final bool complete =
      _isReturning;

  final bool enabled =
      !_isSaving &&
      (startProcessing || complete);

  final String label =
      startProcessing
          ? 'Start Return Inspection'
          : complete
              ? 'Complete Booking'
              : 'Return Unavailable';

  return SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        12,
        AppSpacing.xl,
        12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled
              ? (startProcessing
                  ? _startReturnProcessing
                  : _completeReturn)
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(
              double.infinity,
              52,
            ),
            backgroundColor: enabled
                ? AppColors.primary
                : AppColors.background,
            foregroundColor: enabled
                ? Colors.white
                : AppColors.textSecondary,
            disabledForegroundColor:
                AppColors.textSecondary,
            disabledBackgroundColor:
                AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
          ),
          child: _isSaving
    ? Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Flexible(
            child: Text(
              _savingMessage,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      )
    : Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color: Colors.white,
            ),
          ),

          if (enabled) ...[
            const SizedBox(
              width: 7,
            ),

            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ],
      ),
        ),
      ),
    ),
  );
}

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    AppColors.textSecondary,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              AppColors.textSecondary,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value.isEmpty
                    ? 'Not specified'
                    : value,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool strong = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              label,
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    strong
                        ? FontWeight.w800
                        : FontWeight.w500,
                color:
                    strong
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                TextStyle(
              fontSize:
                  strong ? 12 : 10,
              fontWeight:
                  strong
                      ? FontWeight.w900
                      : FontWeight.w700,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallValue(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child:
              Text(
            label,
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w800,
            color:
                AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
