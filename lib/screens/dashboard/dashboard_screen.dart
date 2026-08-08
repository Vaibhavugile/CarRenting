import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../vehicles/add_vehicle_screen.dart';
import '../vehicles/vehicle_list_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  UserModel? _user;

  DashboardStatsModel? _stats;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  //
  // LOW READ:
  //
  // 1 × users/{uid}
  // 1 × dashboardStats/{branchCode}
  // ============================================================

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user =
          await AuthService.instance
              .getCurrentUserProfile();

      if (user == null) {
        throw Exception(
          'User profile not found.',
        );
      }

      if (user.branchCode == null ||
          user.branchCode!.isEmpty) {
        throw Exception(
          'Branch setup is incomplete.',
        );
      }

      final stats =
          await DashboardService.instance
              .getStats(
        user.branchCode!,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _loading = false;
      });
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/',
      (route) => false,
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

      appBar: AppBar(
        automaticallyImplyLeading:
            false,

        title: const Text(
          'Dashboard',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading
                    ? null
                    : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },

            itemBuilder:
                (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Text(
                      'Logout',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_user == null ||
        _stats == null) {
      return const Center(
        child: Text(
          'Unable to load dashboard.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ),

        children: [
          _buildWelcome(),

          const SizedBox(
            height: AppSpacing.xxl,
          ),

          _buildBranchCard(),

          const SizedBox(
            height: AppSpacing.xxl,
          ),

_buildRevenueCard(),

const SizedBox(
  height: AppSpacing.xxl,
),

// ============================================================
// VEHICLES
// ============================================================

_buildVehicleStats(),

const SizedBox(
  height: AppSpacing.xxl,
),

// ============================================================
// BOOKINGS
// ============================================================

_buildBookingStats(),

const SizedBox(
  height: AppSpacing.xxl,
),

// ============================================================
// QUICK ACTIONS
// ============================================================

_buildQuickActions(),



          const SizedBox(
            height: AppSpacing.xxl,
          ),

          _buildQuickActions(),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    final name =
        _user!.fullName.trim();

    final firstName =
        name.split(' ').first;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Good day, $firstName',

          style:
              Theme.of(context)
                  .textTheme
                  .headlineMedium,
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        Text(
          'Here is your rental business overview.',

          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium,
        ),
      ],
    );
  }

  // ============================================================
  // BRANCH CARD
  // ============================================================

  Widget _buildBranchCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
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

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                AppRadius.md,
              ),
            ),

            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Active Branch',

                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            Colors.white70,
                      ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _user!.branchCode!
                      .toUpperCase(),

                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons
                .verified_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVENUE
  // ============================================================

  Widget _buildRevenueCard() {
    final stats = _stats!;

    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border: Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Revenue',

                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge,
                ),
              ),

              const Icon(
                Icons
                    .trending_up_rounded,
                color:
                    AppColors.success,
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          Text(
            '₹${_formatAmount(stats.monthRevenue)}',

            style:
                Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          Text(
            'This month',

            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          const Divider(),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child: _miniMetric(
                  'Today',
                  '₹${_formatAmount(stats.todayRevenue)}',
                ),
              ),

              Expanded(
                child: _miniMetric(
                  'Pending',
                  '₹${_formatAmount(stats.pendingPayments)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLES
  // ============================================================

 

Widget _buildVehicleStats() {
  final stats = _stats!;

  // ============================================================
  // OPEN VEHICLE LIST
  // ============================================================

  Future<void> openVehicleList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const VehicleListScreen(),
      ),
    );
  }

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [
      // ========================================================
      // SECTION HEADER
      // ========================================================

      Material(
        color:
            Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),

          onTap:
              openVehicleList,

          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 4,
            ),

            child: Row(
              children: [
                Expanded(
                  child: _title(
                    'Vehicles',
                    'Current fleet status',
                  ),
                ),

                Container(
                  width: 34,
                  height: 34,

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

                  child: const Icon(
                    Icons
                        .arrow_forward_ios_rounded,

                    size: 14,

                    color:
                        AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(
        height:
            AppSpacing.lg,
      ),

      // ========================================================
      // TOTAL + AVAILABLE
      // ========================================================

      Row(
        children: [
          // ====================================================
          // TOTAL
          // ====================================================

          Expanded(
            child: _statCard(
              icon:
                  Icons.directions_car_rounded,

              title:
                  'Total',

              value:
                  '${stats.totalVehicles}',

              onTap:
                  openVehicleList,
            ),
          ),

          const SizedBox(
            width:
                AppSpacing.md,
          ),

          // ====================================================
          // AVAILABLE
          // ====================================================

          Expanded(
            child: _statCard(
              icon:
                  Icons.check_circle_outline,

              title:
                  'Available',

              value:
                  '${stats.availableVehicles}',

              onTap:
                  openVehicleList,
            ),
          ),
        ],
      ),

      const SizedBox(
        height:
            AppSpacing.md,
      ),

      // ========================================================
      // RENTED + MAINTENANCE
      // ========================================================

      Row(
        children: [
          // ====================================================
          // RENTED
          // ====================================================

          Expanded(
            child: _statCard(
              icon:
                  Icons.key_rounded,

              title:
                  'Rented',

              value:
                  '${stats.rentedVehicles}',

              onTap:
                  openVehicleList,
            ),
          ),

          const SizedBox(
            width:
                AppSpacing.md,
          ),

          // ====================================================
          // MAINTENANCE
          // ====================================================

          Expanded(
            child: _statCard(
              icon:
                  Icons.build_outlined,

              title:
                  'Maintenance',

              value:
                  '${stats.maintenanceVehicles}',

              onTap:
                  openVehicleList,
            ),
          ),
        ],
      ),
    ],
  );
}




  // ============================================================
  // BOOKINGS
  // ============================================================

  Widget _buildBookingStats() {
    final stats = _stats!;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _title(
          'Bookings',
          'Rental activity',
        ),

        const SizedBox(
          height: AppSpacing.lg,
        ),

        Row(
          children: [
            Expanded(
              child: _statCard(
                icon:
                    Icons.today_rounded,
                title: 'Today',
                value:
                    '${stats.todayBookings}',
              ),
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: _statCard(
                icon:
                    Icons
                        .directions_car_filled_rounded,
                title: 'Active',
                value:
                    '${stats.activeBookings}',
              ),
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: _statCard(
                icon:
                    Icons
                        .event_available_rounded,
                title: 'Upcoming',
                value:
                    '${stats.upcomingBookings}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================
Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      _title(
        'Quick Actions',
        'Manage your rental operation',
      ),

      const SizedBox(
        height: AppSpacing.lg,
      ),

      Row(
        children: [
          Expanded(
            child: _actionCard(
              icon:
                  Icons.directions_car_outlined,
              title: 'Add Vehicle',

              onTap: () async {
                final result =
                    await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddVehicleScreen(),
                  ),
                );

                if (result != null &&
                    mounted) {
                  await _loadDashboard();
                }
              },
            ),
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          Expanded(
            child: _actionCard(
              icon:
                  Icons.calendar_month_outlined,
              title: 'New Booking',
            ),
          ),
        ],
      ),

      const SizedBox(
        height: AppSpacing.md,
      ),

      Row(
        children: [
          Expanded(
            child: _actionCard(
              icon:
                  Icons.person_add_alt_1_outlined,
              title: 'Add Customer',
            ),
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          Expanded(
            child: _actionCard(
              icon:
                  Icons.payments_outlined,
              title: 'Payment',
            ),
          ),
        ],
      ),
    ],
  );
}

  // ============================================================
  // STAT CARD
  // ============================================================


Widget _statCard({
  required IconData icon,
  required String title,
  required String value,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.white,

    borderRadius:
        BorderRadius.circular(
      AppRadius.lg,
    ),

    child: InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(
        AppRadius.lg,
      ),

      child: Container(
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
            AppRadius.lg,
          ),

          border: Border.all(
            color:
                AppColors.border,
          ),

          boxShadow:
              AppShadows.card,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // ICON + ARROW
            // ==================================================

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

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

                  child: Icon(
                    icon,
                    size: 21,
                    color:
                        AppColors.primary,
                  ),
                ),

                const Spacer(),

                Container(
                  width: 28,
                  height: 28,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.sm,
                    ),
                  ),

                  child: const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  AppSpacing.lg,
            ),

            // ==================================================
            // VALUE
            // ==================================================

            Text(
              value,

              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              title,

              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                        AppColors.textSecondary,

                    fontWeight:
                        FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}



  // ============================================================
  // ACTION CARD
  // ============================================================

Widget _actionCard({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.white,

    borderRadius:
        BorderRadius.circular(
      AppRadius.lg,
    ),

    child: InkWell(
      borderRadius:
          BorderRadius.circular(
        AppRadius.lg,
      ),

      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),

          border: Border.all(
            color:
                AppColors.border,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              color:
                  AppColors.primary,
            ),

            const SizedBox(
              width:
                  AppSpacing.md,
            ),

            Expanded(
              child: Text(
                title,
                style:
                    Theme.of(context)
                        .textTheme
                        .labelLarge,
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
            ),
          ],
        ),
      ),
    ),
  );
}

  // ============================================================
  // MINI METRIC
  // ============================================================

  Widget _miniMetric(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,

          style:
              Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _title(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge,
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,

          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          AppSpacing.xxl,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 48,
              color:
                  AppColors.danger,
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            Text(
              _error ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            ElevatedButton(
              onPressed:
                  _loadDashboard,

              child:
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
  // MONEY FORMAT
  // ============================================================

  String _formatAmount(
    double amount,
  ) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }

    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }

    return amount
        .toStringAsFixed(0);
  }
}