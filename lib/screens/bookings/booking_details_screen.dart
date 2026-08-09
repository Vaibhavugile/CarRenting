import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:car_rental/models/booking_model.dart';
import '../../app/theme.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState
    extends State<BookingDetailsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late BookingModel _booking;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshBooking() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Read only this booking document. The document is converted
      // through the same BookingModel used by BookingService.
      final snapshot = await _firestore
          .collection('bookings')
          .doc(_booking.id)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        setState(() {
          _booking = BookingModel.fromFirestore(
            snapshot,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // MAIN ACTION
  //
  // Pickup / return screens will be connected once those screens
  // are created. We intentionally do not fake a lifecycle change
  // from this details screen.
  // ============================================================

  void _handleMainAction() {
    switch (_booking.status) {
      case BookingStatus.booking:
        _showMessage(
          'This booking is ready for the pickup stage.',
        );
        return;

      case BookingStatus.pickupPending:
        _showMessage(
          'Pickup screen will handle KM, fuel and vehicle condition.',
        );
        return;

      case BookingStatus.pickup:
        _showMessage(
          'Pickup is recorded. The rental can now be started.',
        );
        return;

      case BookingStatus.active:
        _showMessage(
          'Return screen will handle the vehicle return.',
        );
        return;

      case BookingStatus.returnPending:
        _showMessage(
          'Return processing is ready.',
        );
        return;

      case BookingStatus.returning:
        _showMessage(
          'Complete the return inspection to finish this booking.',
        );
        return;

      case BookingStatus.completed:
        _showMessage(
          'This booking is already completed.',
        );
        return;

      case BookingStatus.cancelled:
        _showMessage(
          'This booking has been cancelled.',
        );
        return;

      case BookingStatus.noShow:
        _showMessage(
          'This booking is marked as no-show.',
        );
        return;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(String value) {
    return value
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
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
        return 'Pickup';

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

  Color _statusColor(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return AppColors.primary;

      case BookingStatus.pickupPending:
        return AppColors.warning;

      case BookingStatus.pickup:
        return AppColors.primary;

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

  IconData _statusIcon(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return Icons.event_note_rounded;

      case BookingStatus.pickupPending:
        return Icons.schedule_rounded;

      case BookingStatus.pickup:
        return Icons.key_rounded;

      case BookingStatus.active:
        return Icons.directions_car_filled_rounded;

      case BookingStatus.returnPending:
        return Icons.assignment_return_rounded;

      case BookingStatus.returning:
        return Icons.sync_rounded;

      case BookingStatus.completed:
        return Icons.check_circle_rounded;

      case BookingStatus.cancelled:
        return Icons.close_rounded;

      case BookingStatus.noShow:
        return Icons.person_off_rounded;
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

  String _money(double value) {
    return NumberFormat(
      '#,##0.##',
    ).format(value);
  }

  String _dateTime(DateTime value) {
    return DateFormat(
      'dd MMM yyyy • hh:mm a',
    ).format(value);
  }

  String _date(DateTime value) {
    return DateFormat(
      'dd MMM yyyy',
    ).format(value);
  }

  String _fuelLabel(
    FuelLevel? fuel,
  ) {
    if (fuel == null) {
      return 'Not recorded';
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

  String _mainActionLabel() {
    switch (_booking.status) {
      case BookingStatus.booking:
        return 'Prepare Pickup';

      case BookingStatus.pickupPending:
        return 'Start Pickup';

      case BookingStatus.pickup:
        return 'Start Rental';

      case BookingStatus.active:
        return 'Start Return';

      case BookingStatus.returnPending:
        return 'Process Return';

      case BookingStatus.returning:
        return 'Complete Return';

      case BookingStatus.completed:
        return 'View Completed';

      case BookingStatus.cancelled:
        return 'Booking Cancelled';

      case BookingStatus.noShow:
        return 'Booking No-Show';
    }
  }

  bool _mainActionEnabled() {
    return _booking.status !=
            BookingStatus.completed &&
        _booking.status !=
            BookingStatus.cancelled &&
        _booking.status !=
            BookingStatus.noShow;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(
            16,
          ),
          content: Text(
            message,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
          ),
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

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar:
          _buildAppBar(
        statusColor,
      ),
      bottomNavigationBar:
          _buildBottomAction(
        statusColor,
      ),
      body:
          RefreshIndicator(
        onRefresh:
            _refreshBooking,
        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            130,
          ),
          children: [
            _buildBookingHeader(
              statusColor,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildRentalPeriod(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildCustomerCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildVehicleCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildLocationCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildStatusTimeline(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildPricingCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildInspectionCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildDocumentsCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildAgreementCard(),
            if (_booking.customerNotes != null &&
                _booking.customerNotes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: AppSpacing.lg,
              ),
              _buildNotesCard(
                title:
                    'Customer Notes',
                icon:
                    Icons.chat_bubble_outline_rounded,
                text:
                    _booking.customerNotes!,
              ),
            ],
            if (_booking.internalNotes != null &&
                _booking.internalNotes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: AppSpacing.lg,
              ),
              _buildNotesCard(
                title:
                    'Internal Notes',
                icon:
                    Icons.notes_rounded,
                text:
                    _booking.internalNotes!,
              ),
            ],
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildAuditCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    Color statusColor,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          AppColors.background,
      surfaceTintColor:
          Colors.transparent,
      titleSpacing:
          0,
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
        'Booking Details',
        style:
            TextStyle(
          fontSize: 19,
          fontWeight:
              FontWeight.w800,
          color:
              AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          tooltip:
              'Refresh',
          onPressed:
              _isRefreshing
                  ? null
                  : _refreshBooking,
          icon:
              _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                    ),
        ),
        const SizedBox(
          width: AppSpacing.sm,
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildBookingHeader(
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
                      'BOOKING NUMBER',
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
                      height: 6,
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
              _statusBadge(
                _booking.status,
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
          Row(
            children: [
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons.directions_car_rounded,
                  label:
                      'Vehicle',
                  value:
                      _booking.vehicleName,
                ),
              ),
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons.payments_rounded,
                  label:
                      'Total',
                  value:
                      '₹${_money(_booking.totalAmount)}',
                ),
              ),
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons
                          .account_balance_wallet_rounded,
                  label:
                      'Pending',
                  value:
                      '₹${_money(_booking.pendingAmount)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color:
              AppColors.textSecondary,
        ),
        const SizedBox(
          width: 7,
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
                  fontSize: 9,
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
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

  Widget _statusBadge(
    BookingStatus status,
  ) {
    final color =
        _statusColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(
              status,
            ),
            size: 14,
            color:
                color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            _statusLabel(
              status,
            ),
            style:
                TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
              color:
                  color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL PERIOD
  // ============================================================

  Widget _buildRentalPeriod() {
    return _sectionCard(
      title:
          'Rental Period',
      icon:
          Icons.schedule_rounded,
      child:
          Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _dateBlock(
                  title:
                      'PICKUP',
                  icon:
                      Icons.login_rounded,
                  dateTime:
                      _booking.pickupDateTime,
                ),
              ),
              _durationBadge(),
              Expanded(
                child:
                    _dateBlock(
                  title:
                      'RETURN',
                  icon:
                      Icons.logout_rounded,
                  dateTime:
                      _booking.returnDateTime,
                  alignRight:
                      true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBlock({
    required String title,
    required IconData icon,
    required DateTime dateTime,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignRight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (!alignRight)
              Icon(
                icon,
                size: 15,
                color:
                    AppColors.textSecondary,
              ),
            if (!alignRight)
              const SizedBox(
                width: 5,
              ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 9,
                letterSpacing:
                    0.6,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppColors.textSecondary,
              ),
            ),
            if (alignRight)
              const SizedBox(
                width: 5,
              ),
            if (alignRight)
              Icon(
                icon,
                size: 15,
                color:
                    AppColors.textSecondary,
              ),
          ],
        ),
        const SizedBox(
          height: 7,
        ),
        Text(
          _date(dateTime),
          textAlign:
              alignRight
                  ? TextAlign.right
                  : TextAlign.left,
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
          DateFormat(
            'hh:mm a',
          ).format(
            dateTime,
          ),
          textAlign:
              alignRight
                  ? TextAlign.right
                  : TextAlign.left,
          style:
              const TextStyle(
            fontSize: 10,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _durationBadge() {
    final totalHours =
        _booking.rentalDays * 24 +
            _booking.rentalHours;

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          20,
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
          Text(
            _booking.rentalDays > 0
                ? '${_booking.rentalDays}d'
                : '${totalHours}h',
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          const Text(
            'duration',
            style:
                TextStyle(
              fontSize: 7,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  Widget _buildCustomerCard() {
    return _sectionCard(
      title:
          'Customer',
      icon:
          Icons.person_outline_rounded,
      child:
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
                  height: 4,
                ),
                Text(
                  _booking.customerPhone,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _smallActionIcon(
            icon:
                Icons.phone_outlined,
            onTap:
                () => _showMessage(
              'Customer call action can be connected here.',
            ),
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
      width: 46,
      height: 46,
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
          fontSize: 16,
          fontWeight:
              FontWeight.w900,
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  Widget _smallActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                AppColors.background,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  AppColors.border,
            ),
          ),
          child:
              Icon(
            icon,
            size: 18,
            color:
                AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE
  // ============================================================

  Widget _buildVehicleCard() {
    return _sectionCard(
      title:
          'Vehicle',
      icon:
          Icons.directions_car_rounded,
      child:
          Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .directions_car_filled_rounded,
                  color:
                      AppColors.primary,
                  size: 25,
                ),
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
                      _booking.vehicleName,
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
                      height: 4,
                    ),
                    Text(
                      _booking
                          .vehicleRegistrationNumber,
                      style:
                          const TextStyle(
                        fontSize: 11,
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
          const SizedBox(
            height: AppSpacing.md,
          ),
          _infoGrid([
            _InfoItem(
              'Vehicle ID',
              _booking.vehicleId,
            ),
            _InfoItem(
              'Branch',
              _booking.branchCode,
            ),
          ]),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATIONS
  // ============================================================

  Widget _buildLocationCard() {
    return _sectionCard(
      title:
          'Locations',
      icon:
          Icons.location_on_outlined,
      child:
          Column(
        children: [
          _locationRow(
            icon:
                Icons.radio_button_checked_rounded,
            title:
                'Pickup Location',
            value:
                _booking.pickupLocation,
          ),
          const SizedBox(
            height: 12,
          ),
          _connectorLine(),
          const SizedBox(
            height: 12,
          ),
          _locationRow(
            icon:
                Icons.location_on_rounded,
            title:
                'Return Location',
            value:
                _booking.returnLocation,
          ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
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
          width: 10,
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
                  fontSize: 9,
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
                  height: 1.4,
                  fontWeight:
                      FontWeight.w700,
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

  Widget _connectorLine() {
    return Row(
      children: [
        const SizedBox(
          width: 8,
        ),
        Container(
          width: 1,
          height: 8,
          color:
              AppColors.border,
        ),
      ],
    );
  }

  // ============================================================
  // STATUS TIMELINE
  // ============================================================

  Widget _buildStatusTimeline() {
    final steps =
        <_TimelineStep>[
      _TimelineStep(
        BookingStatus.booking,
        'Booking',
        'Reservation created',
      ),
      _TimelineStep(
        BookingStatus.pickupPending,
        'Pickup Pending',
        'Waiting for handover',
      ),
      _TimelineStep(
        BookingStatus.pickup,
        'Pickup',
        'Handover recorded',
      ),
      _TimelineStep(
        BookingStatus.active,
        'Active Rental',
        'Vehicle is with customer',
      ),
      _TimelineStep(
        BookingStatus.returnPending,
        'Return Pending',
        'Vehicle return expected',
      ),
      _TimelineStep(
        BookingStatus.returning,
        'Returning',
        'Return inspection in progress',
      ),
      _TimelineStep(
        BookingStatus.completed,
        'Completed',
        'Rental closed',
      ),
    ];

    final currentIndex =
        _timelineIndex(
      _booking.status,
    );

    return _sectionCard(
      title:
          'Booking Timeline',
      icon:
          Icons.route_rounded,
      child:
          Column(
        children:
            List.generate(
          steps.length,
          (index) {
            final step =
                steps[index];

            final completed =
                currentIndex >=
                    index;

            final current =
                _booking.status ==
                    step.status;

            return _timelineRow(
              step:
                  step,
              completed:
                  completed,
              current:
                  current,
              last:
                  index ==
                      steps.length - 1,
            );
          },
        ),
      ),
    );
  }

  int _timelineIndex(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return 0;

      case BookingStatus.pickupPending:
        return 1;

      case BookingStatus.pickup:
        return 2;

      case BookingStatus.active:
        return 3;

      case BookingStatus.returnPending:
        return 4;

      case BookingStatus.returning:
        return 5;

      case BookingStatus.completed:
        return 6;

      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return -1;
    }
  }

  Widget _timelineRow({
    required _TimelineStep step,
    required bool completed,
    required bool current,
    required bool last,
  }) {
    final color =
        current
            ? _statusColor(
                step.status,
              )
            : completed
                ? AppColors.success
                : AppColors.border;

    return IntrinsicHeight(
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child:
                Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration:
                      BoxDecoration(
                    color:
                        completed
                            ? color.withValues(
                                alpha: 0.10,
                              )
                            : AppColors.background,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          color,
                      width:
                          current ? 2 : 1,
                    ),
                  ),
                  child:
                      Icon(
                    completed
                        ? current
                            ? _statusIcon(
                                step.status,
                              )
                            : Icons.check_rounded
                        : Icons.circle,
                    size:
                        completed
                            ? 13
                            : 5,
                    color:
                        color,
                  ),
                ),
                if (!last)
                  Expanded(
                    child:
                        Container(
                  width: 1,
                  margin:
                      const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  color:
                      completed
                          ? AppColors.success
                              .withValues(
                            alpha: 0.35,
                          )
                          : AppColors.border,
                ),
                  ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 18,
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
                            Text(
                          step.title,
                          style:
                              TextStyle(
                            fontSize: 12,
                            fontWeight:
                                current
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                            color:
                                completed
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (current)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                color.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child:
                              Text(
                            'CURRENT',
                            style:
                                TextStyle(
                              fontSize: 7,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing:
                                  0.5,
                              color:
                                  color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    step.subtitle,
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING
  // ============================================================

  Widget _buildPricingCard() {
    final additional =
        _booking.extraKmCharge +
            _booking.fuelCharge +
            _booking.lateReturnCharge +
            _booking.damageCharge +
            _booking.otherCharges;

    return _sectionCard(
      title:
          'Pricing & Payment',
      icon:
          Icons.payments_outlined,
      child:
          Column(
        children: [
          _priceRow(
            'Base Rental',
            _booking.baseRentalAmount,
          ),
          _priceRow(
            'Security Deposit',
            _booking.securityDeposit,
          ),
          if (_booking.extraKmCharge > 0)
            _priceRow(
              'Extra KM',
              _booking.extraKmCharge,
            ),
          if (_booking.fuelCharge > 0)
            _priceRow(
              'Fuel',
              _booking.fuelCharge,
            ),
          if (_booking.lateReturnCharge > 0)
            _priceRow(
              'Late Return',
              _booking.lateReturnCharge,
            ),
          if (_booking.damageCharge > 0)
            _priceRow(
              'Damage',
              _booking.damageCharge,
            ),
          if (_booking.otherCharges > 0)
            _priceRow(
              'Other Charges',
              _booking.otherCharges,
            ),
          if (additional > 0)
            const SizedBox(
              height: 4,
            ),
          if (_booking.discount > 0)
            _priceRow(
              'Discount',
              -_booking.discount,
              valueColor:
                  AppColors.success,
            ),
          if (_booking.tax > 0)
            _priceRow(
              'Tax',
              _booking.tax,
            ),
          const SizedBox(
            height: 10,
          ),
          Container(
            height: 1,
            color:
                AppColors.border,
          ),
          const SizedBox(
            height: 12,
          ),
          _priceRow(
            'Total Amount',
            _booking.totalAmount,
            bold:
                true,
          ),
          const SizedBox(
            height: 8,
          ),
          _priceRow(
            'Paid',
            _booking.paidAmount,
            valueColor:
                AppColors.success,
          ),
          _priceRow(
            'Pending',
            _booking.pendingAmount,
            valueColor:
                _booking.pendingAmount >
                        0
                    ? AppColors.warning
                    : AppColors.success,
            bold:
                true,
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              const Text(
                'Payment Status',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _paymentBadge(
                _booking.paymentStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    double value, {
    Color? valueColor,
    bool bold = false,
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
                fontSize:
                    bold ? 12 : 10,
                fontWeight:
                    bold
                        ? FontWeight.w800
                        : FontWeight.w600,
                color:
                    bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}₹${_money(value.abs())}',
            style:
                TextStyle(
              fontSize:
                  bold ? 13 : 11,
              fontWeight:
                  FontWeight.w800,
              color:
                  valueColor ??
                      AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge(
    PaymentStatus status,
  ) {
    final color =
        _paymentColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        _paymentLabel(
          status,
        ),
        style:
            TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
          color:
              color,
        ),
      ),
    );
  }

  // ============================================================
  // INSPECTION
  // ============================================================

  Widget _buildInspectionCard() {
    return _sectionCard(
      title:
          'Vehicle Inspection',
      icon:
          Icons.speed_rounded,
      child:
          Column(
        children: [
          _inspectionRow(
            icon:
                Icons.speed_rounded,
            label:
                'Starting KM',
            value:
                _booking.startingKm == null
                    ? 'Not recorded'
                    : '${_booking.startingKm} km',
          ),
          _inspectionRow(
            icon:
                Icons.flag_rounded,
            label:
                'Ending KM',
            value:
                _booking.endingKm == null
                    ? 'Not recorded'
                    : '${_booking.endingKm} km',
          ),
          _inspectionRow(
            icon:
                Icons.local_gas_station_outlined,
            label:
                'Fuel at Pickup',
            value:
                _fuelLabel(
              _booking.fuelAtPickup,
            ),
          ),
          _inspectionRow(
            icon:
                Icons.local_gas_station_rounded,
            label:
                'Fuel at Return',
            value:
                _fuelLabel(
              _booking.fuelAtReturn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectionRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child:
          Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Text(
              label,
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textSecondary,
              ),
            ),
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
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENTS
  // ============================================================

  Widget _buildDocumentsCard() {
    final hasLicense =
        _booking.licenseNumber !=
            null &&
        _booking.licenseNumber!
            .trim()
            .isNotEmpty;

    final hasId =
        _booking.idProofNumber !=
            null &&
        _booking.idProofNumber!
            .trim()
            .isNotEmpty;

    return _sectionCard(
      title:
          'Customer Documents',
      icon:
          Icons.badge_outlined,
      child:
          Column(
        children: [
          _documentRow(
            title:
                'Driving License',
            subtitle:
                hasLicense
                    ? _booking.licenseNumber!
                    : 'Not provided',
            available:
                hasLicense,
            imageUrl:
                _booking.licenseImageUrl,
            expiry:
                _booking.licenseExpiryDate,
          ),
          const SizedBox(
            height: 10,
          ),
          _documentRow(
            title:
                _booking.idProofType?.isNotEmpty ==
                        true
                    ? _booking.idProofType!
                    : 'ID Proof',
            subtitle:
                hasId
                    ? _booking.idProofNumber!
                    : 'Not provided',
            available:
                hasId,
            imageUrl:
                _booking.idProofImageUrl,
          ),
        ],
      ),
    );
  }

  Widget _documentRow({
    required String title,
    required String subtitle,
    required bool available,
    String? imageUrl,
    DateTime? expiry,
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
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  available
                      ? AppColors.success
                          .withValues(
                        alpha: 0.08,
                      )
                      : AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              available
                  ? Icons
                      .verified_outlined
                  : Icons
                      .description_outlined,
              size: 19,
              color:
                  available
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
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
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                if (expiry != null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Expires ${_date(expiry)}',
                    style:
                        const TextStyle(
                      fontSize: 8,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (imageUrl != null &&
              imageUrl
                  .trim()
                  .isNotEmpty)
            const Icon(
              Icons
                  .image_outlined,
              size: 18,
              color:
                  AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AGREEMENT
  // ============================================================

  Widget _buildAgreementCard() {
    return _sectionCard(
      title:
          'Agreement',
      icon:
          Icons.description_outlined,
      child:
          _infoGrid([
        _InfoItem(
          'Agreement No.',
          _booking.agreementNumber
                  .trim()
                  .isEmpty
              ? 'Not provided'
              : _booking.agreementNumber,
        ),
        _InfoItem(
          'Terms Accepted',
          _booking.termsAccepted
              ? 'Yes'
              : 'No',
        ),
        _InfoItem(
          'Customer Signature',
          _booking.customerSignatureUrl !=
                      null &&
                  _booking.customerSignatureUrl!
                      .trim()
                      .isNotEmpty
              ? 'Available'
              : 'Not added',
        ),
        _InfoItem(
          'Staff Signature',
          _booking.staffSignatureUrl !=
                      null &&
                  _booking.staffSignatureUrl!
                      .trim()
                      .isNotEmpty
              ? 'Available'
              : 'Not added',
        ),
      ]),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesCard({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return _sectionCard(
      title:
          title,
      icon:
          icon,
      child:
          Text(
        text,
        style:
            const TextStyle(
          fontSize: 11,
          height: 1.5,
          color:
              AppColors.textSecondary,
        ),
      ),
    );
  }

  // ============================================================
  // AUDIT
  // ============================================================

  Widget _buildAuditCard() {
    return _sectionCard(
      title:
          'Booking Information',
      icon:
          Icons.info_outline_rounded,
      child:
          _infoGrid([
        _InfoItem(
          'Booking ID',
          _booking.id,
        ),
        _InfoItem(
          'Business',
          _booking.businessId,
        ),
        _InfoItem(
          'Created',
          _dateTime(
            _booking.createdAt,
          ),
        ),
        _InfoItem(
          'Updated',
          _dateTime(
            _booking.updatedAt,
          ),
        ),
        _InfoItem(
          'Created By',
          _booking.createdBy,
        ),
        _InfoItem(
          'Confirmed By',
          _booking.confirmedBy ??
              '—',
        ),
        _InfoItem(
          'Started By',
          _booking.startedBy ??
              '—',
        ),
        _InfoItem(
          'Completed By',
          _booking.completedBy ??
              '—',
        ),
      ]),
    );
  }

  // ============================================================
  // COMMON CARDS
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

  Widget _infoGrid(
    List<_InfoItem> items,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth;

        final columns =
            width >= 560
                ? 3
                : 2;

        final rows =
            <Widget>[];

        for (
          var i = 0;
          i < items.length;
          i += columns
        ) {
          final rowItems =
              items.skip(i).take(
                columns,
              );

          rows.add(
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children:
                  rowItems
                      .map(
                        (
                          item,
                        ) =>
                            Expanded(
                          child:
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              right: 12,
                              bottom: 14,
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
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
                                  height: 4,
                                ),
                                Text(
                                  item.value,
                                  maxLines:
                                      3,
                                  overflow:
                                      TextOverflow.ellipsis,
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
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          );
        }

        return Column(
          children:
              rows,
        );
      },
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction(
    Color statusColor,
  ) {
    final enabled =
        _mainActionEnabled();

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
              Border(
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
          height: 50,
          child:
              ElevatedButton(
            onPressed:
                enabled
                    ? _handleMainAction
                    : null,
            style:
                ElevatedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                50,
              ),
              backgroundColor:
                  enabled
                      ? statusColor
                      : AppColors.background,
              foregroundColor:
                  enabled
                      ? Colors.white
                      : AppColors.textSecondary,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.lg,
                ),
              ),
            ),
            child:
                Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  _mainActionLabel(),
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
}

// ============================================================
// DATA CLASSES
// ============================================================

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(
    this.label,
    this.value,
  );
}

class _TimelineStep {
  final BookingStatus status;
  final String title;
  final String subtitle;

  const _TimelineStep(
    this.status,
    this.title,
    this.subtitle,
  );
}
