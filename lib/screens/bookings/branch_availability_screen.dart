
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/vehicle_model.dart';
import '../../services/booking_service.dart';
import 'availability_screen.dart';
class BranchAvailabilityScreen extends StatefulWidget {
  const BranchAvailabilityScreen({
    super.key,
  });

  @override
  State<BranchAvailabilityScreen> createState() =>
      _BranchAvailabilityScreenState();
}

class _BranchAvailabilityScreenState
    extends State<BranchAvailabilityScreen> {
  // ============================================================
  // RENTAL PERIOD
  // ============================================================
final TextEditingController _vehicleSearchController =
    TextEditingController();

String _vehicleSearchQuery = '';
  DateTime? _pickupDate;
  DateTime? _returnDate;

  TimeOfDay _pickupTime = const TimeOfDay(
    hour: 10,
    minute: 0,
  );

  TimeOfDay _returnTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  );

  // ============================================================
  // AVAILABILITY
  // ============================================================

  bool _isChecking = false;

  bool _hasCheckedAvailability = false;

  List<VehicleModel> _availableVehicles = [];

  VehicleModel? _selectedVehicle;

  // ============================================================
  // BUILD
  // ============================================================
@override
void dispose() {
  _vehicleSearchController.dispose();
  super.dispose();
}
Widget _buildVehicleSearchBar() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppRadius.lg,
      ),
      border: Border.all(
        color: AppColors.border,
      ),
      boxShadow: AppShadows.card,
    ),
    child: TextField(
      controller: _vehicleSearchController,
      onChanged: (value) {
        setState(() {
          _vehicleSearchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search vehicle or registration...',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: _vehicleSearchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _vehicleSearchController.clear();

                  setState(() {
                    _vehicleSearchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Vehicle Availability',
        ),
        actions: [
          if (_hasCheckedAvailability)
            IconButton(
              tooltip: 'Refresh availability',
              onPressed: _isChecking
                  ? null
                  : _checkAvailability,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildHeader(),

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    _buildRentalPeriod(),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    _buildDurationSummary(),

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    _buildCheckButton(),

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    _buildResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          _selectedVehicle != null
              ? _buildBottomSelectionBar()
              : null,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.lg,
                  ),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.pill,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE AVAILABILITY',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          const Text(
            'Find an available vehicle',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Choose the exact pickup and return period. '
            'We will check your entire branch and show '
            'only vehicles available for that time.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.55,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Rental Period',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'When does the customer need the vehicle?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child: _dateTimeCard(
                  label: 'Pickup',
                  date: _pickupDate,
                  time: _pickupTime,
                  icon:
                      Icons.login_rounded,
                  onDateTap:
                      _selectPickupDate,
                  onTimeTap:
                      _selectPickupTime,
                ),
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: _dateTimeCard(
                  label: 'Return',
                  date: _returnDate,
                  time: _returnTime,
                  icon:
                      Icons.logout_rounded,
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
  // DATE TIME CARD
  // ============================================================

  Widget _dateTimeCard({
    required String label,
    required DateTime? date,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final hasDate = date != null;

    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
        border: Border.all(
          color: hasDate
              ? AppColors.primary.withValues(
                  alpha: 0.18,
                )
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.sm,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          InkWell(
            onTap: onDateTap,
            borderRadius:
                BorderRadius.circular(
              AppRadius.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    date == null
                        ? 'Select date'
                        : _formatDate(date),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: date == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          InkWell(
            onTap: onTimeTap,
            borderRadius:
                BorderRadius.circular(
              AppRadius.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 11,
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
  // DURATION SUMMARY
  // ============================================================

  Widget _buildDurationSummary() {
    if (_pickupDate == null ||
        _returnDate == null) {
      return const SizedBox.shrink();
    }

    final pickup = _combineDateAndTime(
      _pickupDate!,
      _pickupTime,
    );

    final returnTime = _combineDateAndTime(
      _returnDate!,
      _returnTime,
    );

    if (!returnTime.isAfter(pickup)) {
      return const SizedBox.shrink();
    }

    final duration =
        returnTime.difference(pickup);

    final totalHours =
        duration.inMinutes / 60;

    final days =
        duration.inDays;

    final hours =
        duration.inHours % 24;

    String durationText;

    if (days > 0 && hours > 0) {
      durationText =
          '$days day${days == 1 ? '' : 's'} '
          '$hours hour${hours == 1 ? '' : 's'}';
    } else if (days > 0) {
      durationText =
          '$days day${days == 1 ? '' : 's'}';
    } else {
      durationText =
          '${totalHours.toStringAsFixed(1)} hours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.05,
        ),
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timelapse_rounded,
            size: 20,
            color: AppColors.primary,
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          const Text(
            'Rental duration',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          Text(
            durationText,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
    final canCheck =
        _pickupDate != null &&
            _returnDate != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            canCheck && !_isChecking
                ? _checkAvailability
                : null,
        child: AnimatedSwitcher(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          child: _isChecking
              ? const SizedBox(
                  key: ValueKey(
                    'loading',
                  ),
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey(
                    'button',
                  ),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.search_rounded,
                      size: 19,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Check Availability',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Widget _buildResults() {
    if (!_hasCheckedAvailability) {
      return _buildInitialState();
    }

    if (_availableVehicles.isEmpty) {
      return _buildEmptyState();
    }

    return _buildAvailableVehicles();
  }

  // ============================================================
  // INITIAL STATE
  // ============================================================

  Widget _buildInitialState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _emptyIcon(
            Icons.directions_car_outlined,
            AppColors.primary,
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          const Text(
            'Ready to find a vehicle?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Select your rental period above and '
            'check the branch availability.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _emptyIcon(
            Icons.event_busy_rounded,
            AppColors.danger,
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          const Text(
            'No vehicles available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'There are no rentable vehicles available '
            'for the selected date and time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          OutlinedButton.icon(
            onPressed:
                _checkAvailability,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label:
                const Text(
              'Check Again',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 30,
        color: color,
      ),
    );
  }

  // ============================================================
  // AVAILABLE VEHICLES
  // ============================================================

  Widget _buildAvailableVehicles() {
  final filteredVehicles = _availableVehicles.where((vehicle) {
    if (_vehicleSearchQuery.isEmpty) {
      return true;
    }

    final vehicleName = _vehicleName(vehicle).toLowerCase();

    final registration =
        vehicle.registrationNumber.toLowerCase();

    final make = vehicle.make.toLowerCase();
    final model = vehicle.model.toLowerCase();
    final variant = vehicle.variant.toLowerCase();

    return vehicleName.contains(_vehicleSearchQuery) ||
        registration.contains(_vehicleSearchQuery) ||
        make.contains(_vehicleSearchQuery) ||
        model.contains(_vehicleSearchQuery) ||
        variant.contains(_vehicleSearchQuery);
  }).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildVehicleSearchBar(),

      const SizedBox(
        height: AppSpacing.lg,
      ),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Vehicles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _vehicleSearchQuery.isEmpty
                      ? 'Available for your selected rental period'
                      : '${filteredVehicles.length} vehicle${filteredVehicles.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                AppRadius.pill,
              ),
            ),
            child: Text(
              '${filteredVehicles.length}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(
        height: AppSpacing.lg,
      ),

      if (filteredVehicles.isEmpty)
        _buildNoVehicleSearchResult()
      else
        ...filteredVehicles.map(
          _buildVehicleCard,
        ),
    ],
  );
}
Widget _buildNoVehicleSearchResult() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(
      AppSpacing.xl,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppRadius.xl,
      ),
      border: Border.all(
        color: AppColors.border,
      ),
    ),
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.07,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        const Text(
          'No vehicles found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          'No available vehicle matches '
          '"$_vehicleSearchQuery".',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildVehicleCard(
    VehicleModel vehicle,
  ) {
    final isSelected =
        _selectedVehicle?.id ==
            vehicle.id;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 180,
      ),
      margin: const EdgeInsets.only(
        bottom: AppSpacing.md,
      ),
      padding: const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 18,
                      offset:
                          const Offset(
                        0,
                        6,
                      ),
                    ),
                  ]
                : AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGE
              // ==================================================

              _vehicleImage(
                vehicle,
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              // ==================================================
              // DETAILS
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _vehicleName(
                              vehicle,
                            ),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),

                        if (isSelected)
                          const Icon(
                            Icons
                                .check_circle_rounded,
                            color:
                                AppColors.primary,
                            size: 19,
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      vehicle
                          .registrationNumber,
                      style:
                          const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing:
                            0.5,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _infoChip(
                          Icons
                              .local_gas_station_outlined,
                          vehicle
                              .fuelType,
                        ),
                        _infoChip(
                          Icons
                              .settings_outlined,
                          vehicle
                              .transmission,
                        ),
                        _infoChip(
                          Icons
                              .calendar_today_outlined,
                          '${vehicle.year}',
                        ),
                      ],
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
            color: AppColors.border,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Row(
            children: [
              Expanded(
                child: _priceColumn(
                  label: 'Daily',
                  value:
                      '₹${vehicle.dailyRate.toStringAsFixed(0)}',
                ),
              ),

              _verticalDivider(),

              Expanded(
                child: _priceColumn(
                  label: 'Weekly',
                  value:
                      '₹${vehicle.weeklyRate.toStringAsFixed(0)}',
                ),
              ),

              _verticalDivider(),

              Expanded(
                child: _priceColumn(
                  label: 'Monthly',
                  value:
                      '₹${vehicle.monthlyRate.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: isSelected
                ? OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedVehicle = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Vehicle Selected',
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _selectVehicle(vehicle);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Select Vehicle',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLE IMAGE
  // ============================================================

  Widget _vehicleImage(
    VehicleModel vehicle,
  ) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          vehicle.imageUrl != null &&
                  vehicle.imageUrl!
                      .trim()
                      .isNotEmpty
              ? Image.network(
                  vehicle.imageUrl!,
                  fit: BoxFit.cover,
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
                      size: 32,
                    );
                  },
                )
              : const Icon(
                  Icons
                      .directions_car_rounded,
                  color:
                      AppColors.primary,
                  size: 32,
                ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.sm,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style:
                const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize: 8,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICE COLUMN
  // ============================================================

  Widget _priceColumn({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 9,
            fontWeight:
                FontWeight.w600,
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
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  // ============================================================
  // BOTTOM SELECTED VEHICLE BAR
  // ============================================================

  Widget _buildBottomSelectionBar() {
    final vehicle =
        _selectedVehicle!;

    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding:
            const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  AppColors.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.06,
              ),
              blurRadius: 18,
              offset:
                  const Offset(
                0,
                -5,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Text(
                    'Selected vehicle',
                    style:
                        TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    _vehicleName(
                      vehicle,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _continueWithVehicle,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue'),
                    SizedBox(
                      width: 7,
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // SELECT VEHICLE
  // ============================================================

  void _selectVehicle(
    VehicleModel vehicle,
  ) {
    setState(() {
      _selectedVehicle =
          vehicle;
    });
  }

  // ============================================================
  // CONTINUE
  //
  // Booking/customer screen will be connected next.
  // ============================================================

  void _continueWithVehicle() {
  final vehicle = _selectedVehicle;

  if (vehicle == null) {
    return;
  }

  if (_pickupDate == null ||
      _returnDate == null) {
    _showError(
      'Please select pickup and return dates.',
    );
    return;
  }

  final pickupDateTime = _combineDateAndTime(
    _pickupDate!,
    _pickupTime,
  );

  final returnDateTime = _combineDateAndTime(
    _returnDate!,
    _returnTime,
  );

  if (!returnDateTime.isAfter(pickupDateTime)) {
    _showError(
      'Return time must be after pickup time.',
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AvailabilityScreen(
        vehicle: vehicle,
        initialPickupDateTime: pickupDateTime,
        initialReturnDateTime: returnDateTime,
      ),
    ),
  );
}

  // ============================================================
  // CHECK BRANCH AVAILABILITY
  // ============================================================

  Future<void>
      _checkAvailability() async {
    if (_pickupDate == null ||
        _returnDate == null) {
      _showError(
        'Please select pickup and return dates.',
      );
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

    // ==========================================================
    // VALIDATE DATE/TIME
    // ==========================================================

    if (!returnTime.isAfter(
      pickup,
    )) {
      _showError(
        'Return time must be after pickup time.',
      );
      return;
    }

    // ==========================================================
    // CLEAR OLD RESULT
    // ==========================================================

    setState(() {
      _isChecking = true;
      _hasCheckedAvailability = false;
      _availableVehicles = [];
      _selectedVehicle = null;
    });

    try {
      // ========================================================
      // SAME BOOKING SERVICE
      //
      // This checks the entire current branch.
      // ========================================================

      final vehicles =
          await BookingService
              .instance
              .checkBranchAvailability(
        requestedPickup:
            pickup,
        requestedReturn:
            returnTime,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availableVehicles =
            vehicles;
        _hasCheckedAvailability =
            true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // ============================================================
  // PICKUP DATE
  // ============================================================

  Future<void>
      _selectPickupDate() async {
    final now =
        DateTime.now();

    final selected =
        await showDatePicker(
      context: context,

      initialDate:
          _pickupDate ??
              now,

      firstDate:
          DateTime(
        now.year,
        now.month,
        now.day,
      ),

      lastDate:
          now.add(
        const Duration(
          days: 730,
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

    if (selected == null) {
      return;
    }

    setState(() {
      _pickupDate =
          selected;

      if (_returnDate != null &&
          _returnDate!
              .isBefore(
            selected,
          )) {
        _returnDate = null;
      }

      _hasCheckedAvailability =
          false;

      _availableVehicles =
          [];

      _selectedVehicle =
          null;
    });
  }

  // ============================================================
  // RETURN DATE
  // ============================================================

  Future<void>
      _selectReturnDate() async {
    final now =
        DateTime.now();

    final firstDate =
        _pickupDate ??
            DateTime(
              now.year,
              now.month,
              now.day,
            );

    final selected =
        await showDatePicker(
      context: context,

      initialDate:
          _returnDate ??
              firstDate,

      firstDate:
          firstDate,

      lastDate:
          now.add(
        const Duration(
          days: 730,
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

    if (selected == null) {
      return;
    }

    setState(() {
      _returnDate =
          selected;

      _hasCheckedAvailability =
          false;

      _availableVehicles =
          [];

      _selectedVehicle =
          null;
    });
  }

  // ============================================================
  // PICKUP TIME
  // ============================================================

  Future<void>
      _selectPickupTime() async {
    final selected =
        await showTimePicker(
      context: context,
      initialTime:
          _pickupTime,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _pickupTime =
          selected;

      _hasCheckedAvailability =
          false;

      _availableVehicles =
          [];

      _selectedVehicle =
          null;
    });
  }

  // ============================================================
  // RETURN TIME
  // ============================================================

  Future<void>
      _selectReturnTime() async {
    final selected =
        await showTimePicker(
      context: context,
      initialTime:
          _returnTime,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _returnTime =
          selected;

      _hasCheckedAvailability =
          false;

      _availableVehicles =
          [];

      _selectedVehicle =
          null;
    });
  }

  // ============================================================
  // DATE + TIME
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

  // ============================================================
  // DATE FORMAT
  // ============================================================

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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        content:
            Text(message),
      ),
    );
  }
}
