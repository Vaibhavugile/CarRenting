import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/vehicle_model.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState
    extends State<VehicleDetailsScreen> {
  // ============================================================
  // GETTERS
  // ============================================================

  VehicleModel get vehicle =>
      widget.vehicle;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
        ),

        actions: [
          IconButton(
            tooltip: 'More',
            onPressed:
                _showMoreActions,
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: CustomScrollView(
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
                    _buildVehicleHero(),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    _buildQuickActions(),

                    const SizedBox(
                      height:
                          AppSpacing.xxl,
                    ),

                    _buildVehicleInformation(),

                    const SizedBox(
                      height:
                          AppSpacing.xxl,
                    ),

                    _buildRentalPricing(),

                    const SizedBox(
                      height:
                          AppSpacing.xxl,
                    ),

                    _buildCurrentStatus(),

                    const SizedBox(
                      height:
                          AppSpacing.xxl,
                    ),

                    _buildVehicleActivity(),

                    const SizedBox(
                      height:
                          AppSpacing.xxl,
                    ),

                    _buildDangerZone(),
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
  // VEHICLE HERO
  // ============================================================

  Widget _buildVehicleHero() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.primary,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        boxShadow:
            AppShadows.floating,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 70,
                height: 70,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.12,
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
                              width: 70,
                              height: 70,
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
                                      Colors.white,
                                  size: 34,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons
                                .directions_car_rounded,
                            color:
                                Colors.white,
                            size: 34,
                          ),
              ),

              const SizedBox(
                width:
                    AppSpacing.lg,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      _vehicleTitle(),

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      vehicle
                          .registrationNumber,

                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                AppSpacing.xl,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _heroMetric(
                  label:
                      'Current KM',
                  value:
                      _formatNumber(
                    vehicle.currentKm,
                  ),
                ),
              ),

              _heroDivider(),

              Expanded(
                child:
                    _heroMetric(
                  label:
                      'Year',
                  value:
                      '${vehicle.year}',
                ),
              ),

              _heroDivider(),

              Expanded(
                child:
                    _heroMetric(
                  label:
                      'Type',
                  value:
                      _capitalize(
                    vehicle.vehicleType,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                AppSpacing.lg,
          ),

          Row(
            children: [
              _statusBadge(
                vehicle.status,
                light:
                    true,
              ),

              const Spacer(),

              Text(
                _capitalize(
                  vehicle.color,
                ),
                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO METRIC
  // ============================================================

  Widget _heroMetric({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          value,

          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize:
                18,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          label,

          style:
              const TextStyle(
            color:
                Colors.white60,
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
  // HERO DIVIDER
  // ============================================================

  Widget _heroDivider() {
    return Container(
      height: 35,
      width: 1,

      margin:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.md,
      ),

      color:
          Colors.white24,
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child:
              _actionButton(
            icon:
                Icons.edit_outlined,
            label:
                'Edit',
            onTap:
                _editVehicle,
          ),
        ),

        const SizedBox(
          width:
              AppSpacing.md,
        ),

        Expanded(
          child:
              _actionButton(
            icon:
                Icons.sync_alt_rounded,
            label:
                'Status',
            onTap:
                _changeStatus,
          ),
        ),

        const SizedBox(
          width:
              AppSpacing.md,
        ),

        Expanded(
          child:
              _actionButton(
            icon:
                Icons.build_outlined,
            label:
                'Service',
            onTap:
                _openMaintenance,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(
        AppRadius.lg,
      ),

      child: InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                AppSpacing.lg,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              AppRadius.lg,
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
              Icon(
                icon,
                size: 21,
                color:
                    AppColors.primary,
              ),

              const SizedBox(
                height: 7,
              ),

              Text(
                label,

                style:
                    const TextStyle(
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE INFORMATION
  // ============================================================

  Widget _buildVehicleInformation() {
    return _sectionCard(
      title:
          'Vehicle Information',

      subtitle:
          'Basic vehicle specifications',

      icon:
          Icons.info_outline_rounded,

      child:
          Column(
        children: [
          _infoRow(
            icon:
                Icons.confirmation_number_outlined,
            label:
                'Registration Number',
            value:
                vehicle.registrationNumber,
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.business_outlined,
            label:
                'Make',
            value:
                vehicle.make,
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.directions_car_outlined,
            label:
                'Model',
            value:
                vehicle.model,
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.auto_awesome_outlined,
            label:
                'Variant',
            value:
                vehicle.variant.isEmpty
                    ? 'Not specified'
                    : vehicle.variant,
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.category_outlined,
            label:
                'Vehicle Type',
            value:
                _capitalize(
              vehicle.vehicleType,
            ),
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.calendar_today_outlined,
            label:
                'Manufacturing Year',
            value:
                '${vehicle.year}',
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.palette_outlined,
            label:
                'Color',
            value:
                _capitalize(
              vehicle.color,
            ),
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.local_gas_station_outlined,
            label:
                'Fuel Type',
            value:
                _capitalize(
              vehicle.fuelType,
            ),
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.settings_outlined,
            label:
                'Transmission',
            value:
                _capitalize(
              vehicle.transmission,
            ),
          ),

          _infoDivider(),

          _infoRow(
            icon:
                Icons.speed_outlined,
            label:
                'Current KM',
            value:
                '${_formatNumber(vehicle.currentKm)} km',
            emphasize:
                true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL PRICING
  // ============================================================

  Widget _buildRentalPricing() {
    return _sectionCard(
      title:
          'Rental Pricing',

      subtitle:
          'Current rental rates',

      icon:
          Icons.payments_outlined,

      child:
          Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _priceCard(
                  icon:
                      Icons.today_outlined,
                  label:
                      'Daily',
                  value:
                      vehicle.dailyRate,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _priceCard(
                  icon:
                      Icons.date_range_outlined,
                  label:
                      'Weekly',
                  value:
                      vehicle.weeklyRate,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                AppSpacing.md,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _priceCard(
                  icon:
                      Icons.calendar_month_outlined,
                  label:
                      'Monthly',
                  value:
                      vehicle.monthlyRate,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _priceCard(
                  icon:
                      Icons.security_outlined,
                  label:
                      'Deposit',
                  value:
                      vehicle.securityDeposit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICE CARD
  // ============================================================

  Widget _priceCard({
    required IconData icon,
    required String label,
    required double value,
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
            size: 20,
            color:
                AppColors.primary,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize:
                  11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            '₹${_formatNumber(value)}',

            style:
                const TextStyle(
              fontSize:
                  17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT STATUS
  // ============================================================

  Widget _buildCurrentStatus() {
    final config =
        _statusConfig(
      vehicle.status,
    );

    return _sectionCard(
      title:
          'Current Status',

      subtitle:
          'Vehicle availability',

      icon:
          Icons.radio_button_checked_rounded,

      child:
          Container(
        padding:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        decoration:
            BoxDecoration(
          color:
              config.background,

          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),

          border:
              Border.all(
            color:
                config.foreground
                    .withValues(
              alpha: 0.15,
            ),
          ),
        ),

        child:
            Row(
          children: [
            Container(
              width: 46,
              height: 46,

              decoration:
                  BoxDecoration(
                color:
                    config.foreground
                        .withValues(
                  alpha: 0.10,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  Icon(
                config.icon,
                color:
                    config.foreground,
                size: 23,
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
                    config.label,

                    style:
                        TextStyle(
                      color:
                          config.foreground,
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    config.description,

                    style:
                        const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed:
                  _changeStatus,

              child:
                  const Text(
                'Change',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITY
  // ============================================================

  Widget _buildVehicleActivity() {
    return _sectionCard(
      title:
          'Vehicle Activity',

      subtitle:
          'Rental and service records',

      icon:
          Icons.history_rounded,

      child:
          Column(
        children: [
          _activityItem(
            icon:
                Icons.calendar_month_outlined,
            title:
                'Booking History',
            subtitle:
                'View all bookings for this vehicle',
            onTap:
                _openBookingHistory,
          ),

          const SizedBox(
            height:
                AppSpacing.md,
          ),

          _activityItem(
            icon:
                Icons.build_circle_outlined,
            title:
                'Maintenance History',
            subtitle:
                'View service and maintenance records',
            onTap:
                _openMaintenance,
          ),

          const SizedBox(
            height:
                AppSpacing.md,
          ),

          _activityItem(
            icon:
                Icons.speed_outlined,
            title:
                'KM / Odometer History',
            subtitle:
                'Track vehicle KM changes',
            onTap:
                _openKmHistory,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY ITEM
  // ============================================================

  Widget _activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          AppColors.surface,

      borderRadius:
          BorderRadius.circular(
        AppRadius.lg,
      ),

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),

        child:
            Padding(
          padding:
              const EdgeInsets.all(
            AppSpacing.lg,
          ),

          child:
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
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.md,
                  ),
                ),

                child:
                    Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size: 21,
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
                      title,

                      style:
                          const TextStyle(
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,

                      style:
                          const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 13,
                color:
                    AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DANGER ZONE
  // ============================================================

  Widget _buildDangerZone() {
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
              AppColors.danger
                  .withValues(
            alpha: 0.15,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .warning_amber_rounded,
                color:
                    AppColors.danger,
                size: 20,
              ),

              const SizedBox(
                width:
                    AppSpacing.sm,
              ),

              Text(
                'Vehicle Controls',

                style:
                    Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),
            ],
          ),

          const SizedBox(
            height:
                AppSpacing.sm,
          ),

          Text(
            'Use these controls carefully. Vehicle deletion should only be used when the vehicle has no active rental or booking.',

            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color:
                      AppColors.textSecondary,
                ),
          ),

          const SizedBox(
            height:
                AppSpacing.lg,
          ),

          OutlinedButton.icon(
            onPressed:
                _deactivateVehicle,

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.danger,

              side:
                  BorderSide(
                color:
                    AppColors.danger
                        .withValues(
                  alpha: 0.35,
                ),
              ),
            ),

            icon:
                const Icon(
              Icons
                  .block_outlined,
            ),

            label:
                Text(
              vehicle.isActive
                  ? 'Deactivate Vehicle'
                  : 'Activate Vehicle',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required String subtitle,
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.md,
                  ),
                ),

                child:
                    Icon(
                  icon,
                  size: 20,
                  color:
                      AppColors.primary,
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
                      title,

                      style:
                          const TextStyle(
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,

                      style:
                          const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                AppSpacing.lg,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool emphasize = false,
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
          width:
              AppSpacing.md,
        ),

        Expanded(
          child:
              Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize:
                  11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(
          width:
              AppSpacing.md,
        ),

        Flexible(
          child:
              Text(
            value,

            textAlign:
                TextAlign.right,

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style:
                TextStyle(
              color:
                  emphasize
                      ? AppColors.primary
                      : AppColors.textPrimary,

              fontSize:
                  12,

              fontWeight:
                  emphasize
                      ? FontWeight.w800
                      : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO DIVIDER
  // ============================================================

  Widget _infoDivider() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            AppSpacing.md,
      ),

      child:
          const Divider(
        height: 1,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    VehicleStatus status, {
    bool light = false,
  }) {
    final config =
        _statusConfig(status);

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
            light
                ? Colors.white
                    .withValues(
                  alpha: 0.14,
                )
                : config.background,

        borderRadius:
            BorderRadius.circular(
          AppRadius.pill,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 7,
            height: 7,

            decoration:
                BoxDecoration(
              color:
                  light
                      ? Colors.white
                      : config.foreground,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            config.label,

            style:
                TextStyle(
              color:
                  light
                      ? Colors.white
                      : config.foreground,

              fontSize:
                  10,

              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CONFIG
  // ============================================================

  _StatusConfig _statusConfig(
    VehicleStatus status,
  ) {
    switch (status) {
      case VehicleStatus.available:
        return _StatusConfig(
          label:
              'AVAILABLE',
          description:
              'Ready for a new rental',
          foreground:
              AppColors.success,
          background:
              AppColors.success
                  .withValues(
            alpha: 0.08,
          ),
          icon:
              Icons.check_circle_outline,
        );

      case VehicleStatus.reserved:
        return _StatusConfig(
          label:
              'RESERVED',
          description:
              'Vehicle has an upcoming booking',
          foreground:
              AppColors.primary,
          background:
              AppColors.primary
                  .withValues(
            alpha: 0.08,
          ),
          icon:
              Icons.event_available_outlined,
        );

      case VehicleStatus.rented:
        return _StatusConfig(
          label:
              'RENTED',
          description:
              'Vehicle is currently with a customer',
          foreground:
              Colors.orange.shade700,
          background:
              Colors.orange
                  .withValues(
            alpha: 0.08,
          ),
          icon:
              Icons.key_outlined,
        );

      case VehicleStatus.maintenance:
        return _StatusConfig(
          label:
              'MAINTENANCE',
          description:
              'Vehicle is unavailable for rental',
          foreground:
              AppColors.danger,
          background:
              AppColors.danger
                  .withValues(
            alpha: 0.08,
          ),
          icon:
              Icons.build_outlined,
        );

      case VehicleStatus.inactive:
        return _StatusConfig(
          label:
              'INACTIVE',
          description:
              'Vehicle is currently disabled',
          foreground:
              AppColors.textSecondary,
          background:
              AppColors.surface,
          icon:
              Icons.block_outlined,
        );
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _editVehicle() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'Edit Vehicle will be connected next.',
        ),
      ),
    );
  }

  void _changeStatus() {
    showModalBottomSheet(
      context:
          context,

      backgroundColor:
          Colors.transparent,

      builder:
          (context) {
        return _buildStatusSheet();
      },
    );
  }

  Widget _buildStatusSheet() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),

      decoration:
          const BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            28,
          ),
        ),
      ),

      child:
          SafeArea(
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child:
                  Container(
                width: 42,
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
              ),
            ),

            const SizedBox(
              height:
                  AppSpacing.xl,
            ),

            const Text(
              'Change Vehicle Status',

              style:
                  TextStyle(
                fontSize:
                    19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Select the current operational status of this vehicle.',

              style:
                  TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize:
                    12,
              ),
            ),

            const SizedBox(
              height:
                  AppSpacing.lg,
            ),

            ...VehicleStatus.values.map(
              (status) {
                final config =
                    _statusConfig(
                  status,
                );

                final selected =
                    vehicle.status ==
                        status;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom:
                        AppSpacing.sm,
                  ),

                  child:
                      Material(
                    color:
                        selected
                            ? config.background
                            : AppColors.surface,

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.lg,
                    ),

                    child:
                        InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.lg,
                      ),

                      onTap: () {
                        Navigator.of(
                          context,
                        ).pop();

                        _showStatusMessage(
                          config.label,
                        );
                      },

                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          AppSpacing.md,
                        ),

                        child:
                            Row(
                          children: [
                            Icon(
                              config.icon,
                              color:
                                  config.foreground,
                            ),

                            const SizedBox(
                              width:
                                  AppSpacing.md,
                            ),

                            Expanded(
                              child:
                                  Text(
                                config.label,

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),

                            if (selected)
                              Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                    config.foreground,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMessage(
    String status,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        content:
            Text(
          'Status change to $status will be connected next.',
        ),
      ),
    );
  }

  void _openMaintenance() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'Maintenance module will be connected next.',
        ),
      ),
    );
  }

  void _openBookingHistory() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'Booking history will be connected next.',
        ),
      ),
    );
  }

  void _openKmHistory() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'KM history will be connected next.',
        ),
      ),
    );
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context:
          context,

      backgroundColor:
          Colors.transparent,

      builder:
          (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),

          decoration:
              const BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                28,
              ),
            ),
          ),

          child:
              SafeArea(
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                ListTile(
                  leading:
                      const Icon(
                    Icons.edit_outlined,
                  ),
                  title:
                      const Text(
                    'Edit Vehicle',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _editVehicle();
                  },
                ),

                ListTile(
                  leading:
                      const Icon(
                    Icons.sync_alt_rounded,
                  ),
                  title:
                      const Text(
                    'Change Status',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _changeStatus();
                  },
                ),

                ListTile(
                  leading:
                      const Icon(
                    Icons.build_outlined,
                  ),
                  title:
                      const Text(
                    'Maintenance',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _openMaintenance();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deactivateVehicle() {
    final action =
        vehicle.isActive
            ? 'deactivate'
            : 'activate';

    showDialog(
      context:
          context,

      builder:
          (context) {
        return AlertDialog(
          title:
              Text(
            '${_capitalize(action)} vehicle?',
          ),

          content:
              Text(
            vehicle.isActive
                ? 'This vehicle will no longer be available for normal rental operations.'
                : 'This vehicle will become active again.',
          ),

          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                context,
              ),

              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(
                  SnackBar(
                    content:
                        Text(
                      'Vehicle $action will be connected next.',
                    ),
                  ),
                );
              },

              child:
                  Text(
                _capitalize(
                  action,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _vehicleTitle() {
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

  String _capitalize(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return '';
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  String _formatNumber(
    num value,
  ) {
    final fixed =
        value is double
            ? value.toStringAsFixed(
                value % 1 == 0
                    ? 0
                    : 2,
              )
            : value.toString();

    final parts =
        fixed.split('.');

    final integerPart =
        parts[0];

    final buffer =
        StringBuffer();

    for (int i = 0;
        i < integerPart.length;
        i++) {
      final position =
          integerPart.length -
              i;

      buffer.write(
        integerPart[i],
      );

      if (position > 1 &&
          position % 3 == 1) {
        buffer.write(',');
      }
    }

    if (parts.length > 1) {
      return '${buffer.toString()}.${parts[1]}';
    }

    return buffer.toString();
  }
}

// ============================================================
// STATUS CONFIG
// ============================================================

class _StatusConfig {
  final String label;
  final String description;
  final Color foreground;
  final Color background;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.description,
    required this.foreground,
    required this.background,
    required this.icon,
  });
}