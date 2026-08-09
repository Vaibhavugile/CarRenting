
import 'package:flutter/material.dart';

import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/booking_service.dart';
import '../../app/theme.dart';

class AvailabilityScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const AvailabilityScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<AvailabilityScreen> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState
    extends State<AvailabilityScreen> {
  // ============================================================
  // STATE
  // ============================================================

  late DateTime _visibleMonth;

  DateTime? _pickupDate;
  DateTime? _returnDate;

  TimeOfDay _pickupTime =
      const TimeOfDay(
    hour: 10,
    minute: 0,
  );

  TimeOfDay _returnTime =
      const TimeOfDay(
    hour: 18,
    minute: 0,
  );

  List<BookingModel> _bookings = [];

  bool _isLoading =
      false;

  bool _isChecking =
      false;

  BookingAvailabilityResult?
      _availability;

  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  VehicleModel get vehicle =>
      widget.vehicle;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final now =
        DateTime.now();

    _visibleMonth =
        DateTime(
      now.year,
      now.month,
      1,
    );

    _loadMonthBookings();
  }

  // ============================================================
  // LOAD BOOKINGS FOR CURRENT MONTH
  // ============================================================

  Future<void>
      _loadMonthBookings() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final start =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        1,
      );

      final end =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
        1,
      );

      final bookings =
          await BookingService
              .instance
              .getVehicleBookingsForCalendar(
        vehicleId:
            vehicle.id,
        rangeStart:
            start,
        rangeEnd:
            end,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings =
            bookings;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar:
          AppBar(
        title:
            const Text(
          'Availability',
        ),

        actions: [
          IconButton(
            onPressed:
                _loadMonthBookings,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            CustomScrollView(
          physics:
              const BouncingScrollPhysics(),

          slivers: [
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                120,
              ),

              sliver:
                  SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    _buildVehicleHeader(),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    _buildLegend(),

                    const SizedBox(
                      height:
                          AppSpacing.lg,
                    ),

                    _buildCalendar(),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    _buildRentalPeriod(),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    _buildAvailabilityResult(),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    _buildCheckButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE HEADER
  // ============================================================

  Widget _buildVehicleHeader() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border:
            Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child:
          Row(
        children: [
          Container(
            width: 56,
            height: 56,

            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
                      .withValues(
                alpha: 0.08,
              ),

              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),

            child:
                vehicle.imageUrl != null &&
                        vehicle.imageUrl!
                            .trim()
                            .isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          AppRadius.lg,
                        ),

                        child:
                            Image.network(
                          vehicle.imageUrl!,
                          width: 56,
                          height: 56,
                          fit:
                              BoxFit.cover,

                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .directions_car_rounded,
                              color:
                                  AppColors.primary,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons
                            .directions_car_rounded,
                        color:
                            AppColors.primary,
                        size: 28,
                      ),
          ),

          const SizedBox(
            width:
                AppSpacing.md,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  _vehicleName(),

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  vehicle
                      .registrationNumber,

                  style:
                      const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        0.7,
                  ),
                ),
              ],
            ),
          ),

          _statusPill(),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLE STATUS
  // ============================================================

  Widget _statusPill() {
    final available =
        vehicle.isActive &&
            vehicle.status ==
                VehicleStatus.available;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.md,
        vertical: 7,
      ),

      decoration:
          BoxDecoration(
        color:
            available
                ? AppColors.success
                    .withValues(
                  alpha: 0.08,
                )
                : AppColors.danger
                    .withValues(
                  alpha: 0.08,
                ),

        borderRadius:
            BorderRadius.circular(
          AppRadius.pill,
        ),
      ),

      child:
          Text(
        available
            ? 'AVAILABLE'
            : vehicle.status.name
                .toUpperCase(),

        style:
            TextStyle(
          color:
              available
                  ? AppColors.success
                  : AppColors.danger,

          fontSize:
              9,

          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem(
          color:
              AppColors.success,
          label:
              'Available',
        ),

        const SizedBox(
          width:
              AppSpacing.lg,
        ),

        _legendItem(
          color:
              AppColors.danger,
          label:
              'Booked',
        ),

        const SizedBox(
          width:
              AppSpacing.lg,
        ),

        _legendItem(
          color:
              AppColors.warning,
          label:
              'Selected',
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Container(
          width: 9,
          height: 9,

          decoration:
              BoxDecoration(
            color:
                color,

            shape:
                BoxShape.circle,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        Text(
          label,

          style:
              const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize:
                10,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _buildCalendar() {
    final days =
        _daysInMonth(
      _visibleMonth,
    );

    final firstDay =
        DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final offset =
        firstDay.weekday - 1;

    final totalCells =
        ((offset + days.length) / 7)
            .ceil() *
            7;

    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border:
            Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child:
          Column(
        children: [
          _buildMonthHeader(),

          const SizedBox(
            height:
                AppSpacing.lg,
          ),

          _buildWeekDays(),

          const SizedBox(
            height:
                AppSpacing.sm,
          ),

          GridView.builder(
            shrinkWrap:
                true,

            physics:
                const NeverScrollableScrollPhysics(),

            itemCount:
                totalCells,

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  7,

              mainAxisSpacing:
                  8,

              crossAxisSpacing:
                  6,

              childAspectRatio:
                  0.85,
            ),

            itemBuilder:
                (context, index) {
              if (index <
                  offset) {
                return const SizedBox();
              }

              final dayIndex =
                  index -
                      offset;

              if (dayIndex >=
                  days.length) {
                return const SizedBox();
              }

              final date =
                  days[dayIndex];

              return _buildDayCell(
                date,
              );
            },
          ),

          if (_isLoading)
            const Padding(
              padding:
                  EdgeInsets.only(
                top:
                    AppSpacing.md,
              ),

              child:
                  LinearProgressIndicator(
                minHeight:
                    2,
              ),
            ),

          if (_error != null)
            Padding(
              padding:
                  const EdgeInsets.only(
                top:
                    AppSpacing.md,
              ),

              child:
                  Text(
                _error!,

                style:
                    const TextStyle(
                  color:
                      AppColors.danger,
                  fontSize:
                      11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH HEADER
  // ============================================================

  Widget _buildMonthHeader() {
    return Row(
      children: [
        Expanded(
          child:
              Text(
            _monthName(
              _visibleMonth.month,
            ),

            style:
                const TextStyle(
              fontSize:
                  18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${_visibleMonth.year}',

          style:
              const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize:
                13,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(
          width:
              AppSpacing.sm,
        ),

        _calendarArrow(
          icon:
              Icons.chevron_left_rounded,

          onTap:
              _previousMonth,
        ),

        const SizedBox(
          width: 6,
        ),

        _calendarArrow(
          icon:
              Icons.chevron_right_rounded,

          onTap:
              _nextMonth,
        ),
      ],
    );
  }

  Widget _calendarArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          AppColors.surface,

      borderRadius:
          BorderRadius.circular(
        AppRadius.md,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        child:
            SizedBox(
          width: 36,
          height: 36,

          child:
              Icon(
            icon,
            size: 20,
            color:
                AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WEEK DAYS
  // ============================================================

  Widget _buildWeekDays() {
    const labels = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return Row(
      children:
          labels.map(
        (label) {
          return Expanded(
            child:
                Center(
              child:
                  Text(
                label,

                style:
                    const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize:
                      8,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      0.4,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // DAY CELL
  // ============================================================

  Widget _buildDayCell(
    DateTime date,
  ) {
    final isPast =
        _isPastDate(
      date,
    );

    final isToday =
        _isSameDate(
      date,
      DateTime.now(),
    );

    final isPickup =
        _pickupDate != null &&
        _isSameDate(
          date,
          _pickupDate!,
        );

    final isReturn =
        _returnDate != null &&
        _isSameDate(
          date,
          _returnDate!,
        );

    final isSelectedRange =
        _isInsideSelectedRange(
      date,
    );

    final bookings =
        _bookingsForDate(
      date,
    );

    final isBooked =
        bookings.isNotEmpty;

    final canSelect =
        !isPast &&
        !_hasMaintenanceConflict(
          date,
        );

    Color background =
        Colors.transparent;

    Color foreground =
        AppColors.textPrimary;

    if (isBooked) {
      background =
          AppColors.danger
              .withValues(
        alpha: 0.10,
      );

      foreground =
          AppColors.danger;
    }

    if (isSelectedRange) {
      background =
          AppColors.primary
              .withValues(
        alpha: 0.10,
      );

      foreground =
          AppColors.primary;
    }

    if (isPickup ||
        isReturn) {
      background =
          AppColors.primary;

      foreground =
          Colors.white;
    }

    if (isPast) {
      foreground =
          AppColors.textSecondary
              .withValues(
        alpha: 0.35,
      );
    }

    return GestureDetector(
      onTap:
          canSelect
              ? () =>
                  _selectDate(
                    date,
                  )
              : null,

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              180,
        ),

        decoration:
            BoxDecoration(
          color:
              background,

          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),

          border:
              isToday
                  ? Border.all(
                      color:
                          AppColors.primary,
                      width:
                          1.2,
                    )
                  : null,
        ),

        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Text(
              '${date.day}',

              style:
                  TextStyle(
                color:
                    foreground,

                fontSize:
                    12,

                fontWeight:
                    isPickup ||
                            isReturn ||
                            isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            _availabilityDot(
              date,
              isSelected:
                  isPickup ||
                      isReturn,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVAILABILITY DOT
  // ============================================================

  Widget _availabilityDot(
    DateTime date, {
    bool isSelected = false,
  }) {
    if (isSelected) {
      return Container(
        width: 5,
        height: 5,

        decoration:
            const BoxDecoration(
          color:
              Colors.white,

          shape:
              BoxShape.circle,
        ),
      );
    }

    final bookings =
        _bookingsForDate(
      date,
    );

    final color =
        bookings.isNotEmpty
            ? AppColors.danger
            : AppColors.success;

    return Container(
      width: 5,
      height: 5,

      decoration:
          BoxDecoration(
        color:
            color,

        shape:
            BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // RENTAL PERIOD
  // ============================================================

  Widget _buildRentalPeriod() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border:
            Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Rental Period',

            style:
                TextStyle(
              fontSize:
                  16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'Select pickup and return date & time.',

            style:
                TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height:
                AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _dateTimeField(
                  label:
                      'Pickup',
                  date:
                      _pickupDate,
                  time:
                      _pickupTime,
                  onDateTap:
                      _selectPickupDate,
                  onTimeTap:
                      _selectPickupTime,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _dateTimeField(
                  label:
                      'Return',
                  date:
                      _returnDate,
                  time:
                      _returnTime,
                  onDateTap:
                      _selectReturnDate,
                  onTimeTap:
                      _selectReturnTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE TIME FIELD
  // ============================================================

  Widget _dateTimeField({
    required String label,
    required DateTime? date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.surface,

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
          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize:
                  10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          InkWell(
            onTap:
                onDateTap,

            borderRadius:
                BorderRadius.circular(
              AppRadius.sm,
            ),

            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 15,
                  color:
                      AppColors.primary,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child:
                      Text(
                    date == null
                        ? 'Select date'
                        : _formatDate(
                            date,
                          ),

                    style:
                        const TextStyle(
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          InkWell(
            onTap:
                onTimeTap,

            borderRadius:
                BorderRadius.circular(
              AppRadius.sm,
            ),

            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .access_time_rounded,
                  size: 16,
                  color:
                      AppColors.primary,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  time.format(
                    context,
                  ),

                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w800,
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
  // AVAILABILITY RESULT
  // ============================================================

  Widget _buildAvailabilityResult() {
    final result =
        _availability;

    if (result == null) {
      return const SizedBox();
    }

    if (result.isAvailable) {
      return _resultCard(
        success:
            true,

        title:
            'Vehicle Available',

        message:
            'This vehicle is available for the selected rental period.',
      );
    }

    final conflict =
        result.firstConflict;

    return _resultCard(
      success:
          false,

      title:
          'Vehicle Unavailable',

      message:
          conflict == null
              ? 'Another booking conflicts with your selected period.'
              : 'Booked from ${_formatDateTime(conflict.pickupDateTime)} to ${_formatDateTime(conflict.returnDateTime)}.',
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _resultCard({
    required bool success,
    required String title,
    required String message,
  }) {
    final color =
        success
            ? AppColors.success
            : AppColors.danger;

    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border:
            Border.all(
          color:
              color.withValues(
            alpha: 0.15,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            success
                ? Icons
                    .check_circle_rounded
                : Icons
                    .error_outline_rounded,

            color:
                color,

            size: 24,
          ),

          const SizedBox(
            width:
                AppSpacing.md,
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
                      TextStyle(
                    color:
                        color,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  message,

                  style:
                      const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize:
                        11,
                    height:
                        1.4,
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
  // CHECK BUTTON
  // ============================================================

  Widget _buildCheckButton() {
    final valid =
        _pickupDate != null &&
            _returnDate != null;

    return SizedBox(
      width:
          double.infinity,

      height: 54,

      child:
          ElevatedButton.icon(
        onPressed:
            valid &&
                    !_isChecking
                ? _checkAvailability
                : null,

        icon:
            _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          Colors.white,
                    ),
                  )
                : const Icon(
                    Icons
                        .event_available_rounded,
                  ),

        label:
            Text(
          _isChecking
              ? 'Checking...'
              : 'Check Availability',
        ),
      ),
    );
  }

  // ============================================================
  // CHECK AVAILABILITY
  // ============================================================

  Future<void>
      _checkAvailability() async {
    if (_pickupDate == null ||
        _returnDate == null) {
      return;
    }

    final pickup =
        _combineDateAndTime(
      _pickupDate!,
      _pickupTime,
    );

    final returnTime =
        _combineDateAndTime(
      _returnDate!,
      _returnTime,
    );

    if (!returnTime
        .isAfter(pickup)) {
      _showError(
        'Return time must be after pickup time.',
      );

      return;
    }

    setState(() {
      _isChecking = true;
      _availability = null;
    });

    try {
      final result =
          await BookingService
              .instance
              .checkAvailability(
        vehicleId:
            vehicle.id,
        requestedPickup:
            pickup,
        requestedReturn:
            returnTime,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availability =
            result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking =
              false;
        });
      }
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  void _selectDate(
    DateTime date,
  ) {
    if (_pickupDate == null) {
      setState(() {
        _pickupDate =
            date;

        _returnDate =
            null;

        _availability =
            null;
      });

      return;
    }

    if (_returnDate == null) {
      if (date.isBefore(
        _pickupDate!,
      )) {
        setState(() {
          _returnDate =
              _pickupDate;

          _pickupDate =
              date;
        });
      } else {
        setState(() {
          _returnDate =
              date;
        });
      }

      _availability = null;

      return;
    }

    setState(() {
      _pickupDate =
          date;

      _returnDate =
          null;

      _availability =
          null;
    });
  }

  // ============================================================
  // PICKUP DATE
  // ============================================================

  void _selectPickupDate() {
    _openDatePicker(
      initialDate:
          _pickupDate ??
              DateTime.now(),

      onSelected:
          (date) {
        setState(() {
          _pickupDate =
              date;

          if (_returnDate !=
                  null &&
              _returnDate!
                  .isBefore(
                date,
              )) {
            _returnDate =
                null;
          }

          _availability =
              null;
        });
      },
    );
  }

  // ============================================================
  // RETURN DATE
  // ============================================================

  void _selectReturnDate() {
    _openDatePicker(
      initialDate:
          _returnDate ??
              _pickupDate ??
              DateTime.now(),

      firstDate:
          _pickupDate ??
              DateTime.now(),

      onSelected:
          (date) {
        setState(() {
          _returnDate =
              date;

          _availability =
              null;
        });
      },
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void>
      _openDatePicker({
    required DateTime initialDate,
    DateTime? firstDate,
    required ValueChanged<DateTime>
        onSelected,
  }) async {
    final selected =
        await showDatePicker(
      context:
          context,

      initialDate:
          initialDate,

      firstDate:
          firstDate ??
              DateTime.now(),

      lastDate:
          DateTime.now().add(
        const Duration(
          days:
              730,
        ),
      ),

      builder:
          (context, child) {
        return Theme(
          data:
              Theme.of(context)
                  .copyWith(
            colorScheme:
                Theme.of(context)
                    .colorScheme
                    .copyWith(
              primary:
                  AppColors.primary,
            ),
          ),

          child:
              child!,
        );
      },
    );

    if (selected !=
        null) {
      onSelected(
        selected,
      );
    }
  }

  // ============================================================
  // PICKUP TIME
  // ============================================================

  Future<void>
      _selectPickupTime() async {
    final selected =
        await showTimePicker(
      context:
          context,

      initialTime:
          _pickupTime,
    );

    if (selected !=
        null) {
      setState(() {
        _pickupTime =
            selected;

        _availability =
            null;
      });
    }
  }

  // ============================================================
  // RETURN TIME
  // ============================================================

  Future<void>
      _selectReturnTime() async {
    final selected =
        await showTimePicker(
      context:
          context,

      initialTime:
          _returnTime,
    );

    if (selected !=
        null) {
      setState(() {
        _returnTime =
            selected;

        _availability =
            null;
      });
    }
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  void _previousMonth() {
    setState(() {
      _visibleMonth =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month -
            1,
        1,
      );
    });

    _loadMonthBookings();
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth =
          DateTime(
        _visibleMonth.year,
        _visibleMonth.month +
            1,
        1,
      );
    });

    _loadMonthBookings();
  }

  // ============================================================
  // BOOKINGS FOR DATE
  // ============================================================

  List<BookingModel>
      _bookingsForDate(
    DateTime date,
  ) {
    final dayStart =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final dayEnd =
        dayStart.add(
      const Duration(
        days: 1,
      ),
    );

    return _bookings
        .where(
          (booking) {
            return booking
                    .pickupDateTime
                    .isBefore(
                  dayEnd,
                ) &&
                booking
                    .returnDateTime
                    .isAfter(
                  dayStart,
                );
          },
        )
        .toList();
  }

  // ============================================================
  // MAINTENANCE PLACEHOLDER
  //
  // Vehicle status is currently stored on VehicleModel.
  // Future maintenance calendar integration can be added here.
  // ============================================================

  bool _hasMaintenanceConflict(
    DateTime date,
  ) {
    return vehicle.status ==
            VehicleStatus.maintenance ||
        vehicle.status ==
            VehicleStatus.inactive;
  }

  // ============================================================
  // SELECTED RANGE
  // ============================================================

  bool _isInsideSelectedRange(
    DateTime date,
  ) {
    if (_pickupDate == null ||
        _returnDate == null) {
      return false;
    }

    final current =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final start =
        DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
    );

    final end =
        DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
    );

    return !current.isBefore(
          start,
        ) &&
        !current.isAfter(
          end,
        );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  bool _isSameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day;
  }

  bool _isPastDate(
    DateTime date,
  ) {
    final today =
        DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final current =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    return current.isBefore(
      today,
    );
  }

  List<DateTime>
      _daysInMonth(
    DateTime month,
  ) {
    final days =
        DateTime(
          month.year,
          month.month + 1,
          0,
        ).day;

    return List.generate(
      days,
      (index) {
        return DateTime(
          month.year,
          month.month,
          index + 1,
        );
      },
    );
  }

  // ============================================================
  // COMBINE DATE + TIME
  // ============================================================

  DateTime _combineDateAndTime(
    DateTime date,
    TimeOfDay time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _monthName(
    int month,
  ) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[
        month - 1];
  }

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(
          2,
          '0',
        );

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute $period';
  }

  String _vehicleName() {
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

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        content:
            Text(
          message.replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }
}

