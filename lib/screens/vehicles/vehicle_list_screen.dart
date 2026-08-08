
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import 'vehicle_details_screen.dart';
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({
    super.key,
  });

  @override
  State<VehicleListScreen> createState() =>
      _VehicleListScreenState();
}

class _VehicleListScreenState
    extends State<VehicleListScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // ============================================================
  // DATA
  // ============================================================

  final List<VehicleModel> _vehicles =
      [];

  UserModel? _user;

  DocumentSnapshot<Map<String, dynamic>>?
      _lastDocument;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  bool _loadingMore = false;

  bool _hasMore = true;

  String? _error;

  String _selectedFilter = 'all';

  static const int _pageSize = 15;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _scrollController.addListener(
      _onScroll,
    );

    _loadInitial();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController
        .removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    _scrollController
        .removeListener(
      _onScroll,
    );

    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIAL LOAD
  //
  // LOW READ:
  //
  // 1 × users/{uid}
  // 1 × vehicles query
  // ============================================================

  Future<void> _loadInitial() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
          _vehicles.clear();
          _lastDocument = null;
          _hasMore = true;
        });
      }

      final user =
          await AuthService.instance
              .getCurrentUserProfile();

      if (user == null) {
        throw Exception(
          'User profile not found.',
        );
      }

      if (user.branchCode == null ||
          user.branchCode!.trim().isEmpty) {
        throw Exception(
          'Branch setup is incomplete.',
        );
      }

      final snapshot =
          await VehicleService.instance
              .getVehicles(
        branchCode:
            user.branchCode!,
        limit:
            _pageSize,
      );

      final vehicles =
          snapshot.docs
              .map(
                VehicleModel
                    .fromFirestore,
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;

        _vehicles.addAll(
          vehicles,
        );

        _lastDocument =
            snapshot.docs.isNotEmpty
                ? snapshot.docs.last
                : null;

        _hasMore =
            snapshot.docs.length >=
                _pageSize;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // LOAD MORE
  //
  // ONE MORE FIRESTORE QUERY ONLY WHEN USER REACHES BOTTOM.
  // ============================================================

  Future<void> _loadMore() async {
    if (_loadingMore ||
        !_hasMore ||
        _user?.branchCode == null) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final snapshot =
          await VehicleService.instance
              .getVehicles(
        branchCode:
            _user!.branchCode!,
        limit:
            _pageSize,
        startAfter:
            _lastDocument,
      );

      final vehicles =
          snapshot.docs
              .map(
                VehicleModel
                    .fromFirestore,
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _vehicles.addAll(
          vehicles,
        );

        _lastDocument =
            snapshot.docs.isNotEmpty
                ? snapshot.docs.last
                : _lastDocument;

        _hasMore =
            snapshot.docs.length >=
                _pageSize;

        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingMore = false;
      });

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position =
        _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  // ============================================================
  // SEARCH
  //
  // LOCAL SEARCH ONLY.
  //
  // No Firestore read.
  // ============================================================

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadInitial();
  }

  // ============================================================
  // FILTERED VEHICLES
  // ============================================================

  List<VehicleModel>
      get _filteredVehicles {
    final search =
        _searchController.text
            .trim()
            .toLowerCase();

    return _vehicles.where(
      (vehicle) {
        // ------------------------------------------------------
        // STATUS FILTER
        // ------------------------------------------------------

        if (_selectedFilter !=
            'all') {
          final status =
              VehicleModel.statusToString(
            vehicle.status,
          );

          if (status !=
              _selectedFilter) {
            return false;
          }
        }

        // ------------------------------------------------------
        // SEARCH
        // ------------------------------------------------------

        if (search.isEmpty) {
          return true;
        }

        final searchable =
            [
          vehicle.registrationNumber,
          vehicle.make,
          vehicle.model,
          vehicle.variant,
          vehicle.vehicleType,
          vehicle.fuelType,
          vehicle.color,
        ].join(' ').toLowerCase();

        return searchable.contains(
          search,
        );
      },
    ).toList();
  }

  // ============================================================
  // COUNTERS
  // ============================================================

  int get _totalCount =>
      _vehicles.length;

  int get _availableCount =>
      _vehicles.where(
        (vehicle) =>
            vehicle.status ==
            VehicleStatus.available,
      ).length;

  int get _reservedCount =>
      _vehicles.where(
        (vehicle) =>
            vehicle.status ==
            VehicleStatus.reserved,
      ).length;

  int get _rentedCount =>
      _vehicles.where(
        (vehicle) =>
            vehicle.status ==
            VehicleStatus.rented,
      ).length;

  int get _maintenanceCount =>
      _vehicles.where(
        (vehicle) =>
            vehicle.status ==
            VehicleStatus.maintenance,
      ).length;

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

      appBar: AppBar(
        title: const Text(
          'Vehicles',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading
                    ? null
                    : _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton:
          _buildAddButton(),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh:
          _refresh,

      child: CustomScrollView(
        controller:
            _scrollController,

        physics:
            const AlwaysScrollableScrollPhysics(),

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
                  _buildHeader(),

                  const SizedBox(
                    height:
                        AppSpacing.xl,
                  ),

                  _buildSearch(),

                  const SizedBox(
                    height:
                        AppSpacing.lg,
                  ),

                  _buildStatusFilters(),

                  const SizedBox(
                    height:
                        AppSpacing.xl,
                  ),

                  _buildFleetSummary(),

                  const SizedBox(
                    height:
                        AppSpacing.xl,
                  ),

                  _buildVehicleSectionTitle(),
                ],
              ),
            ),
          ),

          _buildVehicleSliver(),

          if (_loadingMore)
            SliverToBoxAdapter(
              child:
                  _buildLoadingMore(),
            ),

          SliverToBoxAdapter(
            child:
                const SizedBox(
              height:
                  AppSpacing.xxxl,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Your fleet',
          style:
              Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w800,
              ),
        ),

        const SizedBox(
          height:
              AppSpacing.sm,
        ),

        Text(
          'Manage vehicles, availability and rental pricing.',
          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                    AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,

      textInputAction:
          TextInputAction.search,

      textCapitalization:
          TextCapitalization.characters,

      decoration:
          InputDecoration(
        hintText:
            'Search registration, model or make',

        prefixIcon:
            const Icon(
          Icons.search_rounded,
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
                    ),
                  )
                : null,

        filled:
            true,

        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              AppSpacing.lg,
          vertical:
              AppSpacing.lg,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.border,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,

      child: ListView(
        scrollDirection:
            Axis.horizontal,

        children: [
          _filterChip(
            value: 'all',
            label:
                'All $_totalCount',
            icon:
                Icons.directions_car_outlined,
          ),

          _filterChip(
            value: 'available',
            label:
                'Available $_availableCount',
            icon:
                Icons.check_circle_outline_rounded,
          ),

          _filterChip(
            value: 'reserved',
            label:
                'Reserved $_reservedCount',
            icon:
                Icons.event_available_outlined,
          ),

          _filterChip(
            value: 'rented',
            label:
                'Rented $_rentedCount',
            icon:
                Icons.key_outlined,
          ),

          _filterChip(
            value: 'maintenance',
            label:
                'Service $_maintenanceCount',
            icon:
                Icons.build_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected =
        _selectedFilter ==
            value;

    return Padding(
      padding:
          const EdgeInsets.only(
        right:
            AppSpacing.sm,
      ),

      child:
          ChoiceChip(
        selected:
            selected,

        label:
            Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              icon,
              size: 16,
              color:
                  selected
                      ? Colors.white
                      : AppColors.textSecondary,
            ),

            const SizedBox(
              width: 6,
            ),

            Text(
              label,
            ),
          ],
        ),

        onSelected:
            (_) {
          setState(() {
            _selectedFilter =
                value;
          });
        },

        backgroundColor:
            Colors.white,

        selectedColor:
            AppColors.primary,

        side:
            BorderSide(
          color:
              selected
                  ? AppColors.primary
                  : AppColors.border,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.pill,
          ),
        ),

        labelStyle:
            TextStyle(
          color:
              selected
                  ? Colors.white
                  : AppColors.textPrimary,

          fontWeight:
              FontWeight.w700,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal:
              AppSpacing.sm,
        ),
      ),
    );
  }

  // ============================================================
  // FLEET SUMMARY
  // ============================================================

  Widget _buildFleetSummary() {
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
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.md,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .directions_car_rounded,
                  color:
                      Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Fleet overview',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Current vehicle status',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.w800,
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
              _summaryMetric(
                value:
                    '$_totalCount',
                label:
                    'Total',
              ),

              _summaryDivider(),

              _summaryMetric(
                value:
                    '$_availableCount',
                label:
                    'Available',
              ),

              _summaryDivider(),

              _summaryMetric(
                value:
                    '$_rentedCount',
                label:
                    'Rented',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY METRIC
  // ============================================================

  Widget _summaryMetric({
    required String value,
    required String label,
  }) {
    return Expanded(
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  25,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            label,
            style:
                const TextStyle(
              color:
                  Colors.white70,
              fontSize:
                  11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY DIVIDER
  // ============================================================

  Widget _summaryDivider() {
    return Container(
      height: 38,
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
  // SECTION TITLE
  // ============================================================

  Widget _buildVehicleSectionTitle() {
    final filtered =
        _filteredVehicles.length;

    return Row(
      children: [
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Vehicles',
                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _searchController
                        .text
                        .isNotEmpty ||
                    _selectedFilter !=
                        'all'
                    ? '$filtered vehicles shown'
                    : 'Your branch fleet',

                style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                          AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        if (_hasMore)
          Text(
            'Scroll for more',
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color:
                      AppColors.primary,
                  fontWeight:
                      FontWeight.w700,
                ),
          ),
      ],
    );
  }

  // ============================================================
  // VEHICLE SLIVER
  // ============================================================

  Widget _buildVehicleSliver() {
    final vehicles =
        _filteredVehicles;

    if (vehicles.isEmpty) {
      return SliverToBoxAdapter(
        child:
            _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.xl,
      ),

      sliver:
          SliverList.builder(
        itemCount:
            vehicles.length,

        itemBuilder:
            (context, index) {
          final vehicle =
              vehicles[index];

          return Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  AppSpacing.md,
            ),

            child:
                _buildVehicleCard(
              vehicle,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildVehicleCard(
    VehicleModel vehicle,
  ) {
    return Material(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(
        AppRadius.xl,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        onTap:
            () {
          _openVehicle(
            vehicle,
          );
        },

        child:
            Container(
          padding:
              const EdgeInsets.all(
            AppSpacing.lg,
          ),

          decoration:
              BoxDecoration(
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
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  _vehicleIcon(
                    vehicle,
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
                          _vehicleTitle(
                            vehicle,
                          ),

                          maxLines:
                              1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          vehicle
                              .registrationNumber,

                          style:
                              const TextStyle(
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing:
                                0.7,
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
                    vehicle.status,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    AppSpacing.lg,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height:
                    AppSpacing.md,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _vehicleInfo(
                      icon:
                          Icons.speed_outlined,
                      label:
                          'KM',
                      value:
                          _formatNumber(
                        vehicle.currentKm,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        _vehicleInfo(
                      icon:
                          Icons.local_gas_station_outlined,
                      label:
                          'Fuel',
                      value:
                          _capitalize(
                        vehicle.fuelType,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        _vehicleInfo(
                      icon:
                          Icons.settings_outlined,
                      label:
                          'Gear',
                      value:
                          _capitalize(
                        vehicle.transmission,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        _vehicleInfo(
                      icon:
                          Icons.currency_rupee_rounded,
                      label:
                          'Per day',
                      value:
                          '₹${_formatNumber(vehicle.dailyRate)}',
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
                        Text(
                      '${_capitalize(vehicle.color)} • ${vehicle.year}',
                      style:
                          Theme.of(
                            context,
                          )
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color:
                                AppColors.textSecondary,
                            fontWeight:
                                FontWeight.w600,
                          ),
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE ICON
  // ============================================================

  Widget _vehicleIcon(
    VehicleModel vehicle,
  ) {
    return Container(
      width: 54,
      height: 54,

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
          Icon(
        _vehicleTypeIcon(
          vehicle.vehicleType,
        ),
        color:
            AppColors.primary,
        size: 27,
      ),
    );
  }

  // ============================================================
  // VEHICLE TITLE
  // ============================================================

  String _vehicleTitle(
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
  // VEHICLE TYPE ICON
  // ============================================================

  IconData _vehicleTypeIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'bike':
      case 'scooter':
        return Icons.two_wheeler_rounded;

      case 'suv':
      case 'muv':
        return Icons
            .directions_car_rounded;

      case 'luxury':
        return Icons
            .auto_awesome_rounded;

      default:
        return Icons
            .directions_car_rounded;
    }
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    VehicleStatus status,
  ) {
    final config =
        _statusConfig(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.sm,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            config.background,

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
            width: 6,
            height: 6,

            decoration:
                BoxDecoration(
              color:
                  config.foreground,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            config.label,

            style:
                TextStyle(
              color:
                  config.foreground,

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
          foreground:
              AppColors.success,
          background:
              AppColors.success
                  .withValues(
            alpha: 0.10,
          ),
        );

      case VehicleStatus.reserved:
        return _StatusConfig(
          label:
              'RESERVED',
          foreground:
              AppColors.primary,
          background:
              AppColors.primary
                  .withValues(
            alpha: 0.10,
          ),
        );

      case VehicleStatus.rented:
        return _StatusConfig(
          label:
              'RENTED',
          foreground:
              Colors.orange.shade700,
          background:
              Colors.orange
                  .withValues(
            alpha: 0.10,
          ),
        );

      case VehicleStatus.maintenance:
        return _StatusConfig(
          label:
              'SERVICE',
          foreground:
              AppColors.danger,
          background:
              AppColors.danger
                  .withValues(
            alpha: 0.10,
          ),
        );

      case VehicleStatus.inactive:
        return _StatusConfig(
          label:
              'INACTIVE',
          foreground:
              AppColors.textSecondary,
          background:
              AppColors.surface,
        );
    }
  }

  // ============================================================
  // VEHICLE INFO
  // ============================================================

  Widget _vehicleInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  AppColors.textSecondary,
            ),

            const SizedBox(
              width: 4,
            ),

            Text(
              label,
              style:
                  const TextStyle(
                fontSize:
                    10,
                color:
                    AppColors.textSecondary,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            fontSize:
                11,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final searching =
        _searchController
            .text
            .trim()
            .isNotEmpty;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.xl,
      ),

      child:
          Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.all(
          AppSpacing.xxl,
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
        ),

        child:
            Column(
          children: [
            Container(
              width: 72,
              height: 72,

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
                  Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons
                        .directions_car_outlined,

                size: 34,

                color:
                    AppColors.primary,
              ),
            ),

            const SizedBox(
              height:
                  AppSpacing.lg,
            ),

            Text(
              searching
                  ? 'No vehicles found'
                  : 'No vehicles yet',

              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),

            const SizedBox(
              height:
                  AppSpacing.sm,
            ),

            Text(
              searching
                  ? 'Try another registration number or search term.'
                  : 'Add your first vehicle to start managing your fleet.',

              textAlign:
                  TextAlign.center,

              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                        AppColors.textSecondary,
                  ),
            ),

            if (!searching) ...[
              const SizedBox(
                height:
                    AppSpacing.xl,
              ),

              ElevatedButton.icon(
                onPressed:
                    _openAddVehicle,

                icon:
                    const Icon(
                  Icons
                      .add_circle_outline_rounded,
                ),

                label:
                    const Text(
                  'Add Vehicle',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return ListView(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),

      children: [
        Container(
          width: 180,
          height: 30,

          decoration:
              BoxDecoration(
            color:
                AppColors.surface,

            borderRadius:
                BorderRadius.circular(
              AppRadius.md,
            ),
          ),
        ),

        const SizedBox(
          height:
              AppSpacing.sm,
        ),

        Container(
          width: 280,
          height: 18,

          decoration:
              BoxDecoration(
            color:
                AppColors.surface,

            borderRadius:
                BorderRadius.circular(
              AppRadius.sm,
            ),
          ),
        ),

        const SizedBox(
          height:
              AppSpacing.xl,
        ),

        Container(
          height: 58,

          decoration:
              BoxDecoration(
            color:
                Colors.white,

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
        ),

        const SizedBox(
          height:
              AppSpacing.lg,
        ),

        ...List.generate(
          4,
          (index) =>
              Padding(
            padding:
                const EdgeInsets.only(
              bottom:
                  AppSpacing.md,
            ),

            child:
                Container(
              height: 190,

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
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING MORE
  // ============================================================

  Widget _buildLoadingMore() {
    return const Padding(
      padding:
          EdgeInsets.all(
        AppSpacing.lg,
      ),

      child:
          Center(
        child:
            SizedBox(
          width: 22,
          height: 22,

          child:
              CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          AppSpacing.xxl,
        ),

        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.danger
                        .withValues(
                  alpha: 0.08,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons
                    .error_outline_rounded,

                size: 34,

                color:
                    AppColors.danger,
              ),
            ),

            const SizedBox(
              height:
                  AppSpacing.lg,
            ),

            Text(
              'Unable to load vehicles',

              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),

            const SizedBox(
              height:
                  AppSpacing.sm,
            ),

            Text(
              _error ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

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
                  AppSpacing.xl,
            ),

            ElevatedButton.icon(
              onPressed:
                  _loadInitial,

              icon:
                  const Icon(
                Icons.refresh_rounded,
              ),

              label:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed:
          _openAddVehicle,

      backgroundColor:
          AppColors.primary,

      foregroundColor:
          Colors.white,

      elevation:
          4,

      icon:
          const Icon(
        Icons.add_rounded,
      ),

      label:
          const Text(
        'Add Vehicle',
        style:
            TextStyle(
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN ADD VEHICLE
  // ============================================================

  Future<void>
      _openAddVehicle() async {
    final result =
        await Navigator.of(
      context,
    ).pushNamed(
      '/add-vehicle',
    );

    if (result != null &&
        mounted) {
      await _loadInitial();
    }
  }

  // ============================================================
  // OPEN VEHICLE
  //
  // Vehicle details screen will be connected next.
  // ============================================================

void _openVehicle(
  VehicleModel vehicle,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          VehicleDetailsScreen(
        vehicle: vehicle,
      ),
    ),
  );
}

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            AppColors.danger,

        margin:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),
        ),

        content:
            Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color:
                  Colors.white,
            ),

            const SizedBox(
              width:
                  AppSpacing.md,
            ),

            Expanded(
              child:
                  Text(
                message,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  String _formatNumber(
    num value,
  ) {
    final text =
        value.toStringAsFixed(
      value is double &&
              value % 1 != 0
          ? 2
          : 0,
    );

    final parts =
        text.split('.');

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

  final Color foreground;

  final Color background;

  const _StatusConfig({
    required this.label,
    required this.foreground,
    required this.background,
  });
}

