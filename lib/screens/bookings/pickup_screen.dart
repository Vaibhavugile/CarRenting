import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';

import 'package:car_rental/models/booking_model.dart';
import 'package:car_rental/services/booking_service.dart';
import '../../app/theme.dart';
class PickupScreen extends StatefulWidget {
  final BookingModel booking;

  const PickupScreen({
    super.key,
    required this.booking,
  });

  @override
  State<PickupScreen> createState() =>
      _PickupScreenState();
}

class _PickupScreenState
    extends State<PickupScreen> {
  final BookingService _bookingService =
      BookingService.instance;

  final TextEditingController _startingKmController =
    TextEditingController();

late BookingModel _booking;

FuelLevel _fuelAtPickup =
    FuelLevel.full;

bool _isSaving = false;

final ImagePicker _imagePicker =
    ImagePicker();

final Map<String, File?> _pickupImages = {
  'front': null,
  'rear': null,
  'left': null,
  'right': null,
  'interior': null,
  'extra': null,
};

final Map<String, String> _pickupImageUrls = {};

String? _uploadingPhotoType;

String _savingMessage =
    'Confirm Pickup';

 @override
void initState() {
  super.initState();

  _booking = widget.booking;

  _startingKmController.text =
      _booking.startingKm?.toString() ?? '';

  _fuelAtPickup =
      _booking.fuelAtPickup ??
          FuelLevel.full;

  // Existing uploaded pickup images
  for (final entry
      in _booking.pickupImages.entries) {
    if (entry.value.isNotEmpty) {
      _pickupImageUrls[entry.key] =
          entry.value;
    }
  }
}

  @override
  void dispose() {
    _startingKmController.dispose();
    super.dispose();
  }

  // ============================================================
  // STATUS
  // ============================================================
bool get _isBooking =>
    _booking.status == BookingStatus.booking;

bool get _isPickupRecorded =>
    _booking.status == BookingStatus.pickup;

  // ============================================================
  // ACTION
  // ============================================================

  

  Future<void> _startPickup() async {
  if (_isSaving) return;

  FocusScope.of(context).unfocus();

  final km =
      int.tryParse(
    _startingKmController.text.trim(),
  );

  if (km == null) {
    _showError(
      'Enter a valid starting KM.',
    );
    return;
  }

  if (km < 0) {
    _showError(
      'Starting KM cannot be negative.',
    );
    return;
  }

  // ==========================================================
  // REQUIRED PHOTOS
  // ==========================================================

  

  setState(() {
    _isSaving = true;
    _savingMessage =
        'Preparing pickup...';
  });

  try {
    // ========================================================
    // UPLOAD + OPTIMIZE IMAGES
    // ========================================================

    await _uploadAllPickupImages();

    if (!mounted) return;

    setState(() {
      _savingMessage =
          'Recording pickup...';
    });

    // ========================================================
    // START PICKUP
    // ========================================================

    final updated =
        await _bookingService.startPickup(
      bookingId:
          _booking.id,

      startingKm:
          km,

      fuelAtPickup:
          _fuelAtPickup,

      pickupImages:
          _pickupImageUrls,
    );

    if (!mounted) return;

    setState(() {
      _booking = updated;
      _isSaving = false;
      _savingMessage =
          'Confirm Pickup';
    });

    _showMessage(
      'Pickup recorded successfully.',
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _uploadingPhotoType = null;
      _savingMessage =
          'Confirm Pickup';
    });

    _showError(
      _cleanError(
        e.toString(),
      ),
    );
  }
}
  Future<void> _pickPickupImage(
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
                'Add Vehicle Photo',
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
      _pickupImages[type] =
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

  // Keep reducing until <= 500 KB
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
Future<String> _uploadPickupImage(
  String type,
  File file,
) async {
  final optimized =
      await _optimizeImage(file);

  final storageRef =
      FirebaseStorage.instance
          .ref()
          .child(
            'bookings/${_booking.id}/pickup/$type.jpg',
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
Future<void> _uploadAllPickupImages() async {
  for (final entry
      in _pickupImages.entries) {
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
        await _uploadPickupImage(
      type,
      file,
    );

    _pickupImageUrls[type] =
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

    case 'extra':
      return 'extra photo';

    default:
      return 'vehicle photo';
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

  String _fuelLabel(
    FuelLevel fuel,
  ) {
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
        return Icons
            .local_gas_station_outlined;

      case FuelLevel.quarter:
        return Icons
            .battery_1_bar_rounded;

      case FuelLevel.half:
        return Icons
            .battery_4_bar_rounded;

      case FuelLevel.threeQuarter:
        return Icons
            .battery_5_bar_rounded;

      case FuelLevel.full:
        return Icons
            .battery_full_rounded;
    }
  }

  Color _statusColor(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return AppColors.primary;

      case BookingStatus.pickupPending:
        return AppColors.warning;

      case BookingStatus.pickup:
        return AppColors.success;

      case BookingStatus.active:
        return AppColors.success;

      case BookingStatus.returnPending:
        return AppColors.warning;

      case BookingStatus.returning:
        return AppColors.primary;

      case BookingStatus.completed:
        return AppColors.success;

      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return AppColors.danger;
    }
  }

  String _statusLabel(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return 'Booking';

      case BookingStatus.pickupPending:
        return 'Pickup Pending';

      case BookingStatus.pickup:
        return 'Pickup Recorded';

      case BookingStatus.active:
        return 'Active';

      case BookingStatus.returnPending:
        return 'Return Pending';

      case BookingStatus.returning:
        return 'Returning';

      case BookingStatus.completed:
        return 'Completed';

      case BookingStatus.cancelled:
        return 'Cancelled';

      case BookingStatus.noShow:
        return 'No Show';
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
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor(
      _booking.status,
    );

    final canRecordPickup =
    _isBooking;

final pickupAlreadyRecorded =
    _isPickupRecorded;

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
          'Vehicle Pickup',
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
        canRecordPickup:
            canRecordPickup,
        pickupAlreadyRecorded:
            pickupAlreadyRecorded,
        statusColor:
            statusColor,
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
            _buildHeader(
              statusColor,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildCustomerVehicle(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildRentalSchedule(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            
            _buildOdometerCard(
              enabled:
                  canRecordPickup,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildFuelCard(
              enabled:
                  canRecordPickup,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
           _buildVehiclePhotos(
  enabled:
      canRecordPickup,
),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildPickupSummary(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    Color statusColor,
  ) {
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                  _statusLabel(
                    _booking.status,
                  ),
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
          Container(
            height: 1,
            color:
                AppColors.border,
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          const Text(
            'Pickup is where the vehicle handover data is recorded.',
            style:
                TextStyle(
              fontSize: 11,
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
  // CUSTOMER + VEHICLE
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
          Row(
            children: [
              _avatar(
                _booking.customerName,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking.customerName,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _booking.customerPhone,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Container(
            height: 1,
            color:
                AppColors.border,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .directions_car_filled_rounded,
                  color:
                      AppColors.primary,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking.vehicleName,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _booking
                          .vehicleRegistrationNumber,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(
    String name,
  ) {
    final initial =
        name.trim().isEmpty
            ? '?'
            : name
                .trim()
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      width: 44,
      height: 44,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            AppColors.primary
                .withValues(
          alpha: 0.08,
        ),
        shape:
            BoxShape.circle,
      ),
      child:
          Text(
        initial,
        style:
            const TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w900,
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  Widget _buildRentalSchedule() {
    return _sectionCard(
      title:
          'Pickup Schedule',
      icon:
          Icons.schedule_rounded,
      child:
          Row(
        children: [
          Expanded(
            child:
                _scheduleItem(
              title:
                  'Pickup',
              value:
                  DateFormat(
                'dd MMM yyyy',
              ).format(
                _booking.pickupDateTime,
              ),
              time:
                  DateFormat(
                'hh:mm a',
              ).format(
                _booking.pickupDateTime,
              ),
              icon:
                  Icons.login_rounded,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                _scheduleItem(
              title:
                  'Return',
              value:
                  DateFormat(
                'dd MMM yyyy',
              ).format(
                _booking.returnDateTime,
              ),
              time:
                  DateFormat(
                'hh:mm a',
              ).format(
                _booking.returnDateTime,
              ),
              icon:
                  Icons.logout_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem({
    required String title,
    required String value,
    required String time,
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
          Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
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
                  value,
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
                  time,
                  style:
                      const TextStyle(
                    fontSize: 9,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREPARE
  // ============================================================

  Widget _buildPrepareCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.primary
                .withValues(
          alpha: 0.05,
        ),
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border:
            Border.all(
          color:
              AppColors.primary
                  .withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 21,
            color:
                AppColors.primary,
          ),
          const SizedBox(
            width: 10,
          ),
          const Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup preparation',
                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Move the booking to Pickup Pending first. KM and fuel are recorded only when the actual vehicle handover begins.',
                  style:
                      TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ODOMETER
  // ============================================================

  Widget _buildOdometerCard({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Starting Odometer',
      icon:
          Icons.speed_rounded,
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextField(
            controller:
                _startingKmController,
            enabled:
                enabled,
            keyboardType:
                TextInputType.number,
            textInputAction:
                TextInputAction.done,
            decoration:
                InputDecoration(
              labelText:
                  'Starting KM',
              hintText:
                  'Enter vehicle odometer reading',
              suffixText:
                  'KM',
              prefixIcon:
                  const Icon(
                Icons.speed_rounded,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'The service will verify that this reading is not lower than the vehicle’s current KM.',
            style:
                TextStyle(
              fontSize: 9,
              height: 1.4,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FUEL
  // ============================================================

  Widget _buildFuelCard({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Fuel at Pickup',
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
                _fuelAtPickup ==
                    fuel;

            return ChoiceChip(
              selected:
                  selected,
              onSelected:
                  enabled
                      ? (_) {
                          setState(() {
                            _fuelAtPickup =
                                fuel;
                          });
                        }
                      : null,
              avatar:
                  Icon(
                _fuelIcon(
                  fuel,
                ),
                size: 16,
                color:
                    selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
              label:
                  Text(
                _fuelLabel(
                  fuel,
                ),
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
  // CHECKLIST
  // ============================================================

 

 Widget _buildVehiclePhotos({
  required bool enabled,
}) {
  return _sectionCard(
    title:
        'Vehicle Photos',
    icon:
        Icons.camera_alt_outlined,
    child:
        Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Capture the vehicle condition before handing it over. Front, rear, both sides and interior are required.',
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
            _photoTile(
              type: 'front',
              title: 'Front',
              icon: Icons
                  .directions_car_filled_rounded,
              enabled: enabled,
            ),

            _photoTile(
              type: 'rear',
              title: 'Rear',
              icon: Icons
                  .directions_car_filled_rounded,
              enabled: enabled,
            ),

            _photoTile(
              type: 'left',
              title: 'Left Side',
              icon: Icons
                  .directions_car_rounded,
              enabled: enabled,
            ),

            _photoTile(
              type: 'right',
              title: 'Right Side',
              icon: Icons
                  .directions_car_rounded,
              enabled: enabled,
            ),

            _photoTile(
              type: 'interior',
              title: 'Interior',
              icon: Icons
                  .airline_seat_recline_normal_rounded,
              enabled: enabled,
            ),

            _photoTile(
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
Widget _photoTile({
  required String type,
  required String title,
  required IconData icon,
  required bool enabled,
}) {
  final file =
      _pickupImages[type];

  final existingUrl =
      _pickupImageUrls[type];

  final hasImage =
      file != null ||
      (existingUrl != null &&
          existingUrl.isNotEmpty);

  final isUploading =
      _uploadingPhotoType == type;

  return GestureDetector(
    onTap: enabled
        ? () => _pickPickupImage(type)
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
  // SUMMARY
  // ============================================================

  Widget _buildPickupSummary() {
    final hasKm =
        _startingKmController.text
            .trim()
            .isNotEmpty;

    return _sectionCard(
      title:
          'Pickup Summary',
      icon:
          Icons.summarize_outlined,
      child:
          Column(
        children: [
          _summaryRow(
            'Customer',
            _booking.customerName,
          ),
          _summaryRow(
            'Vehicle',
            _booking.vehicleName,
          ),
          _summaryRow(
            'Registration',
            _booking
                .vehicleRegistrationNumber,
          ),
          _summaryRow(
            'Starting KM',
            hasKm
                ? '${_startingKmController.text.trim()} KM'
                : 'Not recorded',
          ),
          _summaryRow(
            'Fuel',
            _fuelLabel(
              _fuelAtPickup,
            ),
          ),
          _summaryRow(
            'Pickup location',
            _booking.pickupLocation,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                Text(
              label,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Flexible(
            child:
                Text(
              value.isEmpty
                  ? 'Not specified'
                  : value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction({
    required bool canRecordPickup,
    required bool pickupAlreadyRecorded,
    required Color statusColor,
  }) {
    String label;

if (_isBooking) {
  label = 'Confirm Pickup';
} else if (pickupAlreadyRecorded) {
  label = 'Pickup Recorded';
} else {
  label = 'Pickup Not Available';
}

final enabled =
    !_isSaving &&
    _isBooking;

    return SafeArea(
      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          12,
          AppSpacing.xl,
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              AppColors.surface,
          border:
              const Border(
            top:
                BorderSide(
              color:
                  AppColors.border,
            ),
          ),
        ),
        child:
            SizedBox(
          width:
              double.infinity,
          height: 52,
          child:
              ElevatedButton(
            onPressed:
    enabled
        ? _startPickup
        : null,
            style:
                ElevatedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                52,
              ),
              backgroundColor:
                  enabled
                      ? statusColor
                      : AppColors.background,
              foregroundColor:
                  enabled
                      ? Colors.white
                      : AppColors.textSecondary,
              disabledForegroundColor:
                  AppColors.textSecondary,
              disabledBackgroundColor:
                  AppColors.background,
              elevation:
                  0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
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
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
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
            ),
          ),

          if (enabled) ...[
            const SizedBox(
              width: 7,
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
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
  // COMMON CARD
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
}
