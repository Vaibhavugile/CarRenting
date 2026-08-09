import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:car_rental/models/booking_model.dart';
import 'package:car_rental/services/booking_service.dart';
import 'booking_details_screen.dart';
import '../../app/theme.dart';
// Keep your existing theme constants.


class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    super.key,
  });

  @override
  State<BookingsScreen> createState() =>
      _BookingsScreenState();
}

enum _DateFilter {
  all,
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  custom,
}

enum _PaymentFilter {
  all,
  unpaid,
  partiallyPaid,
  paid,
}

class _BookingsScreenState
    extends State<BookingsScreen> {
  final BookingService _bookingService =
      BookingService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<BookingModel> _allBookings = [];
  List<BookingModel> _filteredBookings = [];

  bool _isLoading = true;
  String? _errorMessage;

  BookingStatus? _statusFilter;
  _DateFilter _dateFilter = _DateFilter.all;
  _PaymentFilter _paymentFilter =
      _PaymentFilter.all;

  // Vehicle filter uses the real vehicleId.
  // This keeps vehicles with the same name/registration distinct.
  String? _vehicleFilterId;

  DateTime? _customDate;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _applyFilters,
    );

    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD BOOKINGS
  // ============================================================

  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load the branch's bookings without a status/date
      // restriction. Filtering is intentionally done locally
      // so pickup AND return dates can both participate.
      final bookings =
          await _bookingService.getBookings();

      if (!mounted) return;

      setState(() {
        _allBookings = bookings;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(
          e.toString(),
        );
      });
    }
  }

  // ============================================================
  // FILTERING
  // ============================================================

  void _applyFilters() {
    if (!mounted) return;

    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    final result =
        _allBookings.where((booking) {
      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      final matchesSearch =
          query.isEmpty ||
          booking.bookingNumber
              .toLowerCase()
              .contains(query) ||
          booking.customerName
              .toLowerCase()
              .contains(query) ||
          booking.customerPhone
              .toLowerCase()
              .contains(query) ||
          booking.vehicleName
              .toLowerCase()
              .contains(query) ||
          booking.vehicleRegistrationNumber
              .toLowerCase()
              .contains(query);

      if (!matchesSearch) {
        return false;
      }

      // --------------------------------------------------------
      // VEHICLE
      // --------------------------------------------------------

      if (_vehicleFilterId != null &&
          booking.vehicleId !=
              _vehicleFilterId) {
        return false;
      }

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      if (_statusFilter != null &&
          booking.status !=
              _statusFilter) {
        return false;
      }

      // --------------------------------------------------------
      // PAYMENT
      // --------------------------------------------------------

      if (!_matchesPayment(
        booking,
      )) {
        return false;
      }

      // --------------------------------------------------------
      // DATE
      //
      // A booking matches if EITHER:
      // pickup date OR return date matches.
      // --------------------------------------------------------

      if (!_matchesDate(
        booking,
      )) {
        return false;
      }

      return true;
    }).toList();

    result.sort(
      (a, b) =>
          a.pickupDateTime.compareTo(
        b.pickupDateTime,
      ),
    );

    setState(() {
      _filteredBookings = result;
    });
  }

  bool _matchesPayment(
    BookingModel booking,
  ) {
    switch (_paymentFilter) {
      case _PaymentFilter.all:
        return true;

      case _PaymentFilter.unpaid:
        return booking.paymentStatus ==
            PaymentStatus.unpaid;

      case _PaymentFilter.partiallyPaid:
        return booking.paymentStatus ==
            PaymentStatus.partiallyPaid;

      case _PaymentFilter.paid:
        return booking.paymentStatus ==
            PaymentStatus.paid;
    }
  }

  bool _matchesDate(
    BookingModel booking,
  ) {
    if (_dateFilter ==
        _DateFilter.all) {
      return true;
    }

    final pickup =
        booking.pickupDateTime;
    final returned =
        booking.returnDateTime;

    switch (_dateFilter) {
      case _DateFilter.all:
        return true;

      case _DateFilter.today:
        return _sameDay(
              pickup,
              DateTime.now(),
            ) ||
            _sameDay(
              returned,
              DateTime.now(),
            );

      case _DateFilter.tomorrow:
        final tomorrow =
            DateTime.now().add(
          const Duration(
            days: 1,
          ),
        );

        return _sameDay(
              pickup,
              tomorrow,
            ) ||
            _sameDay(
              returned,
              tomorrow,
            );

      case _DateFilter.thisWeek:
        final now =
            DateTime.now();

        final start =
            _startOfWeek(
          now,
        );

        final end =
            start.add(
          const Duration(
            days: 7,
          ),
        );

        return _dateOverlapsRange(
              pickup,
              returned,
              start,
              end,
            );

      case _DateFilter.thisMonth:
        final now =
            DateTime.now();

        final start =
            DateTime(
          now.year,
          now.month,
          1,
        );

        final end =
            DateTime(
          now.year,
          now.month + 1,
          1,
        );

        return _dateOverlapsRange(
          pickup,
          returned,
          start,
          end,
        );

      case _DateFilter.custom:
        if (_customDate == null) {
          return true;
        }

        return _sameDay(
              pickup,
              _customDate!,
            ) ||
            _sameDay(
              returned,
              _customDate!,
            );
    }
  }

  bool _dateOverlapsRange(
    DateTime pickup,
    DateTime returned,
    DateTime start,
    DateTime end,
  ) {
    return pickup.isBefore(end) &&
        returned.isAfter(start);
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final midnight =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    return midnight.subtract(
      Duration(
        days:
            midnight.weekday - 1,
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickCustomDate() async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          _customDate ??
              DateTime.now(),
      firstDate:
          DateTime(
        DateTime.now().year - 2,
      ),
      lastDate:
          DateTime(
        DateTime.now().year + 5,
      ),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dateFilter =
          _DateFilter.custom;
      _customDate = picked;
    });

    _applyFilters();
  }

  // ============================================================
  // RESET
  // ============================================================

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = null;
      _vehicleFilterId = null;
      _dateFilter =
          _DateFilter.all;
      _paymentFilter =
          _PaymentFilter.all;
      _customDate = null;
    });

    _applyFilters();
  }

  // ============================================================
  // ACTION
  // ============================================================

  Future<void> _handleBookingAction(
    BookingModel booking,
  ) async {
    switch (booking.status) {
      case BookingStatus.booking:
        _showInfo(
          'Booking ${booking.bookingNumber} is ready for pickup scheduling.',
        );
        return;

      case BookingStatus.pickupPending:
        _showInfo(
          'Open the pickup screen to record KM, fuel and vehicle condition.',
        );
        return;

      case BookingStatus.pickup:
        _showInfo(
          'Pickup is recorded. The rental can now be started.',
        );
        return;

      case BookingStatus.active:
        _showInfo(
          'Open the return screen when the vehicle comes back.',
        );
        return;

      case BookingStatus.returnPending:
        _showInfo(
          'Open the return screen to process the vehicle.',
        );
        return;

      case BookingStatus.returning:
        _showInfo(
          'Return is being processed. Complete the final inspection.',
        );
        return;

      case BookingStatus.completed:
        _showInfo(
          'This booking is completed.',
        );
        return;

      case BookingStatus.cancelled:
        _showInfo(
          'This booking is cancelled.',
        );
        return;

      case BookingStatus.noShow:
        _showInfo(
          'This booking is marked as no-show.',
        );
        return;
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
        return Icons.directions_car_rounded;

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
      case PaymentStatus.paid:
        return AppColors.success;

      case PaymentStatus.partiallyPaid:
        return AppColors.warning;

      case PaymentStatus.unpaid:
        return AppColors.danger;

      case PaymentStatus.refunded:
        return AppColors.primary;
    }
  }

  String _dateLabel(
    _DateFilter filter,
  ) {
    switch (filter) {
      case _DateFilter.all:
        return 'All Dates';

      case _DateFilter.today:
        return 'Today';

      case _DateFilter.tomorrow:
        return 'Tomorrow';

      case _DateFilter.thisWeek:
        return 'This Week';

      case _DateFilter.thisMonth:
        return 'This Month';

      case _DateFilter.custom:
        return _customDate == null
            ? 'Custom Date'
            : DateFormat(
                'dd MMM yyyy',
              ).format(
                _customDate!,
              );
    }
  }

  String _groupLabel(
    DateTime date,
  ) {
    final now =
        DateTime.now();

    if (_sameDay(
      date,
      now,
    )) {
      return 'Today';
    }

    final tomorrow =
        now.add(
      const Duration(
        days: 1,
      ),
    );

    if (_sameDay(
      date,
      tomorrow,
    )) {
      return 'Tomorrow';
    }

    return DateFormat(
      'EEE, dd MMM',
    ).format(
      date,
    );
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
          _buildAppBar(),
      body:
          RefreshIndicator(
        onRefresh:
            _loadBookings,
        child:
            _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor:
          AppColors.background,
      surfaceTintColor:
          Colors.transparent,
      titleSpacing:
          AppSpacing.xl,
      title: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Bookings',
            style: TextStyle(
              fontSize: 23,
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
            '${_filteredBookings.length} bookings',
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w500,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip:
              'Refresh',
          onPressed:
              _isLoading
                  ? null
                  : _loadBookings,
          icon:
              const Icon(
            Icons.refresh_rounded,
          ),
        ),
        const SizedBox(
          width: AppSpacing.sm,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          AppSpacing.xl,
        ),
        children: [
          _buildLoadingHeader(),
          const SizedBox(
            height: AppSpacing.xl,
          ),
          ...List.generate(
            4,
            (_) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: AppSpacing.md,
              ),
              child:
                  _buildLoadingCard(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          AppSpacing.xl,
        ),
        children: [
          const SizedBox(
            height: 90,
          ),
          _buildErrorState(),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        120,
      ),
      children: [
        _buildSearch(),
        const SizedBox(
          height: AppSpacing.md,
        ),
        _buildStatusFilters(),
        const SizedBox(
          height: AppSpacing.md,
        ),
        _buildFilterRow(),
        const SizedBox(
          height: AppSpacing.lg,
        ),
        _buildSummary(),
        const SizedBox(
          height: AppSpacing.xl,
        ),
        _buildBookingList(),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
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
          TextField(
        controller:
            _searchController,
        textInputAction:
            TextInputAction.search,
        decoration:
            InputDecoration(
          hintText:
              'Search customer, phone, booking or vehicle',
          hintStyle:
              const TextStyle(
            fontSize: 12,
            color:
                AppColors.textSecondary,
          ),
          prefixIcon:
              const Icon(
            Icons.search_rounded,
            size: 21,
          ),
          suffixIcon:
              _searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                    )
                  : null,
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters() {
    final filters =
        <_StatusFilterItem>[
      const _StatusFilterItem(
        label: 'All',
        status: null,
      ),
      const _StatusFilterItem(
        label: 'Upcoming',
        status: BookingStatus.booking,
      ),
      const _StatusFilterItem(
        label: 'Pickup',
        status: BookingStatus.pickupPending,
      ),
      const _StatusFilterItem(
        label: 'Active',
        status: BookingStatus.active,
      ),
      const _StatusFilterItem(
        label: 'Return',
        status: BookingStatus.returnPending,
      ),
      const _StatusFilterItem(
        label: 'Completed',
        status: BookingStatus.completed,
      ),
    ];

    return SizedBox(
      height: 40,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            filters.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          final item =
              filters[index];

          final selected =
              _statusFilter ==
                  item.status;

          return _filterChip(
            label:
                item.label,
            selected:
                selected,
            onTap: () {
              setState(() {
                _statusFilter =
                    item.status;
              });
              _applyFilters();
            },
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        30,
      ),
      onTap: onTap,
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius:
              BorderRadius.circular(
            30,
          ),
          border:
              Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child:
            Text(
          label,
          style:
              TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
            color: selected
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER ROW
  // ============================================================

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child:
              _dropdownButton(
            icon:
                Icons.directions_car_rounded,
            label:
                _vehicleFilterLabel(),
            onTap:
                _showVehicleFilter,
          ),
        ),
        const SizedBox(
          width: AppSpacing.sm,
        ),
        Expanded(
          child:
              _dropdownButton(
            icon:
                Icons.calendar_month_rounded,
            label:
                _dateLabel(
              _dateFilter,
            ),
            onTap:
                _showDateFilter,
          ),
        ),
        const SizedBox(
          width: AppSpacing.sm,
        ),
        Expanded(
          child:
              _dropdownButton(
            icon:
                Icons.payments_rounded,
            label: _paymentFilter ==
                    _PaymentFilter.all
                ? 'All Payments'
                : _paymentFilter ==
                        _PaymentFilter.paid
                    ? 'Paid'
                    : _paymentFilter ==
                            _PaymentFilter.partiallyPaid
                        ? 'Partially Paid'
                        : 'Unpaid',
            onTap:
                _showPaymentFilter,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VEHICLE FILTER
  // ============================================================

  String _vehicleFilterLabel() {
    if (_vehicleFilterId == null) {
      return 'All Vehicles';
    }

    final options =
        _vehicleFilterOptions();

    for (final vehicle in options) {
      if (vehicle.id == _vehicleFilterId) {
        return vehicle.label;
      }
    }

    return 'All Vehicles';
  }

  List<_VehicleFilterItem> _vehicleFilterOptions() {
    final unique =
        <String, _VehicleFilterItem>{};

    for (final booking in _allBookings) {
      final id =
          booking.vehicleId.trim();

      if (id.isEmpty) {
        continue;
      }

      final name =
          booking.vehicleName.trim();

      final registration =
          booking.vehicleRegistrationNumber
              .trim();

      final label =
          name.isEmpty
              ? registration.isEmpty
                  ? 'Vehicle'
                  : registration
              : registration.isEmpty
                  ? name
                  : '$name • $registration';

      unique.putIfAbsent(
        id,
        () => _VehicleFilterItem(
          id: id,
          label: label,
          vehicleName:
              name.isEmpty
                  ? 'Vehicle'
                  : name,
          registrationNumber:
              registration,
        ),
      );
    }

    final options =
        unique.values.toList();

    options.sort(
      (a, b) => a.label
          .toLowerCase()
          .compareTo(
            b.label.toLowerCase(),
          ),
    );

    return options;
  }

  Future<void> _showVehicleFilter() async {
    final options =
        _vehicleFilterOptions();

    if (options.isEmpty) {
      _showInfo(
        'No vehicles are available in the loaded bookings.',
      );
      return;
    }

    final value =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          AppColors.surface,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child:
                      _sheetHandle(),
                ),
                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),
                const Text(
                  'Select Vehicle',
                  style:
                      TextStyle(
                    fontSize: 18,
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
                  'Filter bookings by vehicle.',
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                const SizedBox(
                  height:
                      AppSpacing.md,
                ),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxHeight:
                        MediaQuery.of(
                              context,
                            ).size.height *
                            0.58,
                  ),
                  child:
                      ListView(
                    shrinkWrap: true,
                    children: [
                      _vehicleFilterTile(
                        context:
                            context,
                        value:
                            '__all_vehicles__',
                        title:
                            'All Vehicles',
                        subtitle:
                            '${_allBookings.length} bookings',
                      ),
                      ...options.map(
                        (vehicle) =>
                            _vehicleFilterTile(
                          context:
                              context,
                          value:
                              vehicle.id,
                          title:
                              vehicle.vehicleName,
                          subtitle:
                              vehicle.registrationNumber
                                      .isEmpty
                                  ? null
                                  : vehicle
                                      .registrationNumber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _vehicleFilterId =
          value == '__all_vehicles__'
              ? null
              : value;
    });

    _applyFilters();
  }

  Widget _vehicleFilterTile({
    required BuildContext context,
    required String value,
    required String title,
    String? subtitle,
  }) {
    final selected =
        value == '__all_vehicles__'
            ? _vehicleFilterId == null
            : _vehicleFilterId == value;

    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color:
              AppColors.primary.withValues(
            alpha: 0.07,
          ),
          borderRadius:
              BorderRadius.circular(11),
        ),
        child:
            const Icon(
          Icons.directions_car_rounded,
          size: 18,
          color:
              AppColors.primary,
        ),
      ),
      title:
          Text(
        title,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style:
            const TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color:
              AppColors.textPrimary,
        ),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
      trailing:
          selected
              ? const Icon(
                  Icons.check_circle_rounded,
                  color:
                      AppColors.primary,
                  size: 20,
                )
              : null,
      onTap: () {
        Navigator.pop(
          context,
          value,
        );
      },
    );
  }

  Widget _dropdownButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        AppRadius.lg,
      ),
      child:
          Container(
        height: 46,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
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
            Expanded(
              child:
                  Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE MENU
  // ============================================================

  Future<void> _showDateFilter() async {
    final value =
        await showModalBottomSheet<
            _DateFilter>(
      context: context,
      backgroundColor:
          AppColors.surface,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              AppSpacing.xl,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child:
                      Text(
                    'Filter by date',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(
                  height:
                      AppSpacing.md,
                ),
                ...[
                  _DateFilter.all,
                  _DateFilter.today,
                  _DateFilter.tomorrow,
                  _DateFilter.thisWeek,
                  _DateFilter.thisMonth,
                  _DateFilter.custom,
                ].map(
                  (
                    item,
                  ) {
                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title:
                          Text(
                        _dateLabel(
                          item,
                        ),
                      ),
                      trailing:
                          _dateFilter ==
                                  item
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      AppColors.primary,
                                )
                              : null,
                      onTap:
                          () async {
                        Navigator.pop(
                          context,
                          item,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value == null) {
      return;
    }

    if (value ==
        _DateFilter.custom) {
      await _pickCustomDate();
      return;
    }

    setState(() {
      _dateFilter =
          value;
      _customDate = null;
    });

    _applyFilters();
  }

  // ============================================================
  // PAYMENT MENU
  // ============================================================

  Future<void> _showPaymentFilter() async {
    final value =
        await showModalBottomSheet<
            _PaymentFilter>(
      context: context,
      backgroundColor:
          AppColors.surface,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (context) {
        return SafeArea(
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              AppSpacing.xl,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child:
                      Text(
                        'Payment status',
                        style:
                            TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(
                  height:
                      AppSpacing.md,
                ),
                ...[
                  _PaymentFilter.all,
                  _PaymentFilter.unpaid,
                  _PaymentFilter.partiallyPaid,
                  _PaymentFilter.paid,
                ].map(
                  (
                    item,
                  ) {
                    final selected =
                        _paymentFilter ==
                            item;

                    final label =
                        item ==
                                _PaymentFilter
                                    .all
                            ? 'All Payments'
                            : item ==
                                    _PaymentFilter
                                        .unpaid
                                ? 'Unpaid'
                                : item ==
                                        _PaymentFilter
                                            .partiallyPaid
                                    ? 'Partially Paid'
                                    : 'Paid';

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title:
                          Text(
                        label,
                      ),
                      trailing:
                          selected
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      AppColors.primary,
                                )
                              : null,
                      onTap:
                          () {
                        Navigator.pop(
                          context,
                          item,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value == null) {
      return;
    }

    setState(() {
      _paymentFilter =
          value;
    });

    _applyFilters();
  }

  Widget _sheetHandle() {
    return Container(
      width: 38,
      height: 4,
      decoration:
          BoxDecoration(
        color:
            AppColors.border,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final active =
        _filteredBookings.where(
      (booking) =>
          booking.status ==
              BookingStatus.active ||
          booking.status ==
              BookingStatus.pickup ||
          booking.status ==
              BookingStatus.returnPending ||
          booking.status ==
              BookingStatus.returning,
    ).length;

    final pending =
        _filteredBookings.where(
      (booking) =>
          booking.pendingAmount > 0,
    ).fold<double>(
      0,
      (
        total,
        booking,
      ) =>
          total +
          booking.pendingAmount,
    );

    return Row(
      children: [
        Expanded(
          child:
              _summaryCard(
            label:
                'Visible',
            value:
                '${_filteredBookings.length}',
            icon:
                Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(
          width: AppSpacing.md,
        ),
        Expanded(
          child:
              _summaryCard(
            label:
                'In Progress',
            value:
                '$active',
            icon:
                Icons.directions_car_filled_rounded,
          ),
        ),
        const SizedBox(
          width: AppSpacing.md,
        ),
        Expanded(
          child:
              _summaryCard(
            label:
                'Pending',
            value:
                '₹${_money(pending)}',
            icon:
                Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        13,
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
          Icon(
            icon,
            size: 18,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            height: 9,
          ),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 15,
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
            label,
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  AppColors.textSecondary,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING LIST
  // ============================================================

  Widget _buildBookingList() {
    if (_filteredBookings.isEmpty) {
      return _buildEmptyState();
    }

    final groups =
        <String, List<BookingModel>>{};

    for (final booking
        in _filteredBookings) {
      final key =
          _groupLabel(
        booking.pickupDateTime,
      );

      groups
          .putIfAbsent(
            key,
            () => [],
          )
          .add(
            booking,
          );
    }

    final children =
        <Widget>[];

    for (final entry
        in groups.entries) {
      children.add(
        _buildGroupHeader(
          entry.key,
        ),
      );

      for (final booking
          in entry.value) {
        children.add(
          Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  AppSpacing.md,
            ),
            child:
                _buildBookingCard(
              booking,
            ),
          ),
        );
      }

      children.add(
        const SizedBox(
          height:
              AppSpacing.sm,
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children:
          children,
    );
  }

  Widget _buildGroupHeader(
    String label,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child:
          Row(
        children: [
          Text(
            label.toUpperCase(),
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  0.8,
              color:
                  AppColors.textSecondary,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Container(
              height: 1,
              color:
                  AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(
    BookingModel booking,
  ) {
    final statusColor =
        _statusColor(
      booking.status,
    );

    final paymentColor =
        _paymentColor(
      booking.paymentStatus,
    );

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(
                booking: booking,
              ),
            ),
          );

          // Refresh when returning so status/payment/amount
          // changes made inside BookingDetailsScreen are visible.
          if (mounted) {
            await _loadBookings();
          }
        },
        child:
            Container(
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
              // ------------------------------------------------
              // TOP
              // ------------------------------------------------

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _vehicleIcon(
                    statusColor,
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
                          booking.vehicleName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 15,
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
                          booking
                              .vehicleRegistrationNumber,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width:
                        AppSpacing.sm,
                  ),
                  _statusBadge(
                    booking.status,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              // ------------------------------------------------
              // BOOKING NUMBER
              // ------------------------------------------------

              Row(
                children: [
                  const Icon(
                    Icons
                        .confirmation_number_outlined,
                    size: 15,
                    color:
                        AppColors.textSecondary,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child:
                        Text(
                      booking.bookingNumber,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _paymentBadge(
                    booking.paymentStatus,
                    paymentColor,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              // ------------------------------------------------
              // CUSTOMER
              // ------------------------------------------------

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
                ),
                child:
                    Row(
                  children: [
                    _avatar(
                      booking.customerName,
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
                            booking.customerName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 12,
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
                            booking.customerPhone,
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
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              // ------------------------------------------------
              // PICKUP / RETURN
              // ------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child:
                        _dateTimeInfo(
                      icon:
                          Icons.login_rounded,
                      title:
                          'Pickup',
                      dateTime:
                          booking
                              .pickupDateTime,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color:
                        AppColors.border,
                  ),
                  Expanded(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.only(
                        left: 14,
                      ),
                      child:
                          _dateTimeInfo(
                        icon:
                            Icons.logout_rounded,
                        title:
                            'Return',
                        dateTime:
                            booking
                                .returnDateTime,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              // ------------------------------------------------
              // AMOUNT
              // ------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child:
                        _amountInfo(
                      'Total',
                      booking.totalAmount,
                    ),
                  ),
                  Expanded(
                    child:
                        _amountInfo(
                      'Paid',
                      booking.paidAmount,
                    ),
                  ),
                  Expanded(
                    child:
                        _amountInfo(
                      'Pending',
                      booking.pendingAmount,
                      highlight:
                          booking.pendingAmount >
                              0,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              // ------------------------------------------------
              // ACTION
              // ------------------------------------------------

              _actionButton(
                booking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleIcon(
    Color color,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child:
          Icon(
        Icons.directions_car_rounded,
        color:
            color,
        size: 21,
      ),
    );
  }

  Widget _avatar(
    String name,
  ) {
    final first =
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
      width: 36,
      height: 36,
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
        first,
        style:
            const TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.w800,
          color:
              AppColors.primary,
        ),
      ),
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
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(
              status,
            ),
            size: 12,
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

  Widget _paymentBadge(
    PaymentStatus status,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.07,
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
              FontWeight.w700,
          color:
              color,
        ),
      ),
    );
  }

  Widget _dateTimeInfo({
    required IconData icon,
    required String title,
    required DateTime dateTime,
  }) {
    return Row(
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
                title,
                style:
                    const TextStyle(
                  fontSize: 9,
                  color:
                      AppColors.textSecondary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                DateFormat(
                  'dd MMM • hh:mm a',
                ).format(
                  dateTime,
                ),
                maxLines: 1,
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

  Widget _amountInfo(
    String label,
    double amount, {
    bool highlight = false,
  }) {
    return Column(
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
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          '₹${_money(amount)}',
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            color: highlight
                ? AppColors.warning
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BookingModel booking,
  ) {
    final action =
        _actionLabel(
      booking.status,
    );

    final enabled =
        booking.status !=
                BookingStatus.completed &&
            booking.status !=
                BookingStatus.cancelled &&
            booking.status !=
                BookingStatus.noShow;

    return SizedBox(
      width:
          double.infinity,
      height: 44,
      child:
          OutlinedButton(
        onPressed:
            enabled
                ? () =>
                    _handleBookingAction(
                      booking,
                    )
                : null,
        style:
            OutlinedButton.styleFrom(
          minimumSize:
              const Size(
            0,
            44,
          ),
          side:
              BorderSide(
            color:
                enabled
                    ? AppColors.border
                    : AppColors.border,
          ),
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
              action,
              style:
                  const TextStyle(
                fontSize: 11,
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
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return 'View Booking';

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
        return 'View Completed Booking';

      case BookingStatus.cancelled:
        return 'Cancelled Booking';

      case BookingStatus.noShow:
        return 'No-Show Booking';
    }
  }

  // ============================================================
  // EMPTY / ERROR / LOADING
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilters =
        _searchController.text
                .trim()
                .isNotEmpty ||
            _statusFilter != null ||
            _vehicleFilterId != null ||
            _dateFilter !=
                _DateFilter.all ||
            _paymentFilter !=
                _PaymentFilter.all;

    return Container(
      padding:
          const EdgeInsets.all(
        28,
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
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
                      .withValues(
                alpha: 0.07,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons
                  .event_available_rounded,
              size: 27,
              color:
                  AppColors.primary,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Text(
            hasFilters
                ? 'No matching bookings'
                : 'No bookings yet',
            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            hasFilters
                ? 'Try changing your filters or search.'
                : 'Bookings created for this branch will appear here.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 11,
              height: 1.5,
              color:
                  AppColors.textSecondary,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(
              height: 16,
            ),
            OutlinedButton(
              onPressed:
                  _clearFilters,
              child:
                  const Text(
                'Clear Filters',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding:
          const EdgeInsets.all(
        26,
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
        children: [
          const Icon(
            Icons
                .cloud_off_rounded,
            size: 42,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'Unable to load bookings',
            style:
                TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            _errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 11,
              height: 1.5,
              color:
                  AppColors.textSecondary,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          OutlinedButton.icon(
            onPressed:
                _loadBookings,
            icon:
                const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label:
                const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      height: 48,
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 260,
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  void _showInfo(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(
            16,
          ),
          content:
              Text(
            message,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      );
  }

  String _money(
    double value,
  ) {
    return NumberFormat(
      '#,##0.##',
    ).format(
      value,
    );
  }
}

// ============================================================
// STATUS FILTER ITEM
// ============================================================

class _StatusFilterItem {
  final String label;
  final BookingStatus? status;

  const _StatusFilterItem({
    required this.label,
    required this.status,
  });
}

// ============================================================
// VEHICLE FILTER ITEM
// ============================================================

class _VehicleFilterItem {
  final String id;
  final String label;
  final String vehicleName;
  final String registrationNumber;

  const _VehicleFilterItem({
    required this.id,
    required this.label,
    required this.vehicleName,
    required this.registrationNumber,
  });
}
