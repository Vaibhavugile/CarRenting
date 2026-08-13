import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  bool _conditionChecked = false;
  bool _customerDocumentsChecked = false;
  bool _agreementChecked = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _booking = widget.booking;

    // If pickup data already exists, show it as the current value.
    _startingKmController.text =
        _booking.startingKm.toString();
    FuelLevel? _fuelAtPickup = _booking.fuelAtPickup;
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

    if (!_conditionChecked) {
      _showError(
        'Confirm that the vehicle condition has been checked.',
      );
      return;
    }

    if (!_customerDocumentsChecked) {
      _showError(
        'Confirm that the customer documents have been checked.',
      );
      return;
    }

    if (!_agreementChecked) {
      _showError(
        'Confirm that the rental agreement and handover details are ready.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated =
          await _bookingService.startPickup(
        bookingId:
            _booking.id,
        startingKm:
            km,
        fuelAtPickup:
            _fuelAtPickup,
      );

      if (!mounted) return;

      setState(() {
        _booking = updated;
      });

      _showMessage(
        'Pickup recorded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _cleanError(
          e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
            _buildChecklist(
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

  Widget _buildChecklist({
    required bool enabled,
  }) {
    return _sectionCard(
      title:
          'Handover Checklist',
      icon:
          Icons.fact_check_outlined,
      child:
          Column(
        children: [
          _checkRow(
            title:
                'Vehicle condition checked',
            subtitle:
                'Exterior and interior condition reviewed before handover.',
            value:
                _conditionChecked,
            enabled:
                enabled,
            onChanged:
                (value) {
                  setState(() {
                    _conditionChecked =
                        value;
                  });
                },
          ),
          const SizedBox(
            height: 10,
          ),
          _checkRow(
            title:
                'Customer documents checked',
            subtitle:
                'License and ID information have been verified.',
            value:
                _customerDocumentsChecked,
            enabled:
                enabled,
            onChanged:
                (value) {
                  setState(() {
                    _customerDocumentsChecked =
                        value;
                  });
                },
          ),
          const SizedBox(
            height: 10,
          ),
          _checkRow(
            title:
                'Agreement and handover ready',
            subtitle:
                'Customer is ready to receive the vehicle.',
            value:
                _agreementChecked,
            enabled:
                enabled,
            onChanged:
                (value) {
                  setState(() {
                    _agreementChecked =
                        value;
                  });
                },
          ),
        ],
      ),
    );
  }

  Widget _checkRow({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Checkbox(
            value:
                value,
            onChanged:
                enabled
                    ? (v) =>
                        onChanged(
                      v ?? false,
                    )
                    : null,
          ),
          const SizedBox(
            width: 4,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 3,
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
                  height: 3,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 9,
                    height: 1.35,
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
            child:
                _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
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
                              Icons
                                  .arrow_forward_rounded,
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
