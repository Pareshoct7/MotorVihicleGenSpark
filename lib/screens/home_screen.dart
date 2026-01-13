import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/database_service.dart';
import '../services/usage_service.dart';
import '../models/vehicle.dart';
import '../models/inspection.dart';
import 'inspection_form_screen.dart';
import 'vehicles_screen.dart';
import 'stores_screen.dart';
import 'drivers_screen.dart';
import 'inspection_history_screen.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'bulk_reports_screen.dart';
import 'settings_screen.dart';
import 'offline_drive_screen.dart';
import '../widgets/agent_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  final List<Animation<double>> _staggeredAnimations = [];
  List<String> _topFeatures = [];
  bool _isLoadingUsage = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create 6 staggered animations
    for (int i = 0; i < 6; i++) {
      _staggeredAnimations.add(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(
            i * 0.1,
            0.6 + (i * 0.05),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }

    _loadUsageData();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadUsageData() async {
    final top = await UsageService.getTopFeatures(limit: 4);
    if (mounted) {
      setState(() {
        _topFeatures = top;
        _isLoadingUsage = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _handleFeatureTap(String featureId, Widget screen) async {
    await UsageService.trackUsage(featureId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      _loadUsageData();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesNeedingAttention =
        DatabaseService.getVehiclesNeedingAttention();
    final allInspections = DatabaseService.getAllInspections();
    final recentInspections = allInspections.take(3).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Greeting
          SliverAppBar.large(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 72, bottom: 16, right: 24),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => setState(() {})),
                icon: Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Stats
                  FadeTransition(
                    opacity: _staggeredAnimations[0],
                    child: SlideTransition(
                      position: _staggeredAnimations[0].drive(
                        Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ),
                      ),
                      child: _buildDashboard(context, allInspections.length),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Smart Suggestions / Alerts
                  if (vehiclesNeedingAttention.isNotEmpty)
                    FadeTransition(
                      opacity: _staggeredAnimations[1],
                      child: _buildAlertsSection(
                        context,
                        vehiclesNeedingAttention,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Dynamic Top Actions
                  FadeTransition(
                    opacity: _staggeredAnimations[2],
                    child: Text(
                      'Top Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingUsage
                      ? const Center(child: CircularProgressIndicator())
                      : FadeTransition(
                          opacity: _staggeredAnimations[2],
                          child: _buildDynamicActions(),
                        ),

                  const SizedBox(height: 32),

                  // Secondary Actions (Horizontal Scroll)
                  FadeTransition(
                    opacity: _staggeredAnimations[3],
                    child: _buildSecondaryActions(),
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  FadeTransition(
                    opacity: _staggeredAnimations[4],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRACK HISTORY',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const InspectionHistoryScreen(),
                            ),
                          ).then((_) => setState(() {})),
                          child: Text('FULL LOG'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _staggeredAnimations[5],
                    child: recentInspections.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: recentInspections
                                .map(
                                  (i) => _buildRecentInspectionItem(context, i),
                                )
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 100), // Space for bottom
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AgentFloatingButton(),
          const SizedBox(height: 16),
          _buildSmartFab(context, vehiclesNeedingAttention),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, int totalInspections) {
    // Calculate Today's Stats
    final allInspections = DatabaseService.getAllInspections();
    final now = DateTime.now();
    final todayCount = allInspections.where((i) {
      return i.inspectionDate.year == now.year &&
             i.inspectionDate.month == now.month &&
             i.inspectionDate.day == now.day;
    }).length;

    // Target for meter (e.g. 10 inspections/day is 100%)
    final double meterValue = (todayCount / 10).clamp(0.0, 1.0);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F26), Color(0xFF0D1117)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: CarbonFiberPainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SYSTEM POWER',
                        style: TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$totalInspections',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        'TOTAL RUNS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () => _handleFeatureTap(
                          UsageService.featureReportsAnalytics,
                          const ReportsScreen(),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4FC3F7,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF4FC3F7,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Color(0xFF4FC3F7),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'PERFORMANCE',
                                style: TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: meterValue),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return CustomPaint(
                          size: const Size(100, 100),
                          painter: SpeedometerPainter(value),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$todayCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notification_important,
              color: Colors.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ALERT HUB',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.registrationNo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.isWofExpired ? 'WOF EXPIRED' : 'REGO EXPIRED',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicActions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: _topFeatures.length,
      itemBuilder: (context, index) {
        final featureId = _topFeatures[index];
        final meta = UsageService.getFeatureMeta(featureId);
        return _buildActionCard(
          context,
          meta['title'],
          IconData(meta['icon'], fontFamily: 'MaterialIcons'),
          _getFeatureScreen(featureId),
          featureId,
          Color(meta['color'] ?? 0xFF4FC3F7),
        );
      },
    );
  }

  Widget _buildSecondaryActions() {
    final unusedFeatures = UsageService.allFeatures
        .where((f) => !_topFeatures.contains(f))
        .toList();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: unusedFeatures.length,
        itemBuilder: (context, index) {
          final featureId = unusedFeatures[index];
          final meta = UsageService.getFeatureMeta(featureId);
          final color = Color(meta['color'] ?? 0xFF4FC3F7);
          return GestureDetector(
            onTap: () =>
                _handleFeatureTap(featureId, _getFeatureScreen(featureId)),
            child: Container(
              margin: EdgeInsets.only(right: 24),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      IconData(meta['icon'], fontFamily: 'MaterialIcons'),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meta['title'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
    String featureId,
    Color color,
  ) {
    return InkWell(
      onTap: () => _handleFeatureTap(featureId, screen),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFeatureScreen(String featureId) {
    switch (featureId) {
      case UsageService.featureNewInspection:
        return const InspectionFormScreen();
      case UsageService.featureManageVehicles:
        return const VehiclesScreen();
      case UsageService.featureManageStores:
        return const StoresScreen();
      case UsageService.featureManageDrivers:
        return const DriversScreen();
      case UsageService.featureOfflineDrive:
        return const OfflineDriveScreen();
      case UsageService.featureBulkReports:
        return const BulkReportsScreen();
      case UsageService.featureReportsAnalytics:
        return const ReportsScreen();
      case UsageService.featureReminders:
        return const RemindersScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildRecentInspectionItem(
    BuildContext context,
    Inspection inspection,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.flag, color: Color(0xFF4FC3F7)),
        ),
        title: Text(
          inspection.vehicleRegistrationNo,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          '${inspection.employeeName} • ${inspection.storeName}',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateFormat.format(inspection.inspectionDate),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.white24),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionFormScreen(
                inspection: inspection,
                isViewOnly: true,
              ),
            ),
          ).then((_) => setState(() {}));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              Icons.timer_off_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'NO TRACK DATA FOUND',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.speed, color: Color(0xFF4FC3F7), size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'TURBO INSPECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          _buildThemedDrawerItem(
            context,
            'Home',
            Icons.home_outlined,
            'home',
            const SizedBox(),
          ),
          const Divider(color: Colors.white12),
          _buildThemedDrawerItem(
            context,
            'Speed Check',
            Icons.speed,
            UsageService.featureNewInspection,
            const InspectionFormScreen(),
          ),
          _buildThemedDrawerItem(
            context,
            'History',
            Icons.history,
            'history',
            const InspectionHistoryScreen(),
          ),
          _buildThemedDrawerItem(
            context,
            'Drive',
            Icons.drive_file_move_outlined,
            UsageService.featureOfflineDrive,
            const OfflineDriveScreen(),
          ),
          const Divider(color: Colors.white12),
          _buildThemedDrawerItem(
            context,
            'Quick Reports',
            Icons.bolt,
            UsageService.featureBulkReports,
            const BulkReportsScreen(),
          ),
          _buildThemedDrawerItem(
            context,
            'Performance',
            Icons.assessment_outlined,
            UsageService.featureReportsAnalytics,
            const ReportsScreen(),
          ),
          const Divider(color: Colors.white12),
          _buildThemedDrawerItem(
            context,
            'Vehicles',
            Icons.directions_car_outlined,
            UsageService.featureManageVehicles,
            const VehiclesScreen(),
          ),
          _buildThemedDrawerItem(
            context,
            'Stores',
            Icons.store_outlined,
            UsageService.featureManageStores,
            const StoresScreen(),
          ),
          _buildThemedDrawerItem(
            context,
            'Drivers',
            Icons.person_outline,
            UsageService.featureManageDrivers,
            const DriversScreen(),
          ),
          const Divider(color: Colors.white12),
          _buildThemedDrawerItem(
            context,
            'Alert Hub',
            Icons.notification_important_outlined,
            UsageService.featureReminders,
            const RemindersScreen(),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.white70),
            title: Text(
              'Settings',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemedDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String featureId,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (featureId == 'home') return;
        if (featureId != 'history') {
          _handleFeatureTap(featureId, screen);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          ).then((_) => setState(() {}));
        }
      },
    );
  }

  Widget _buildSmartFab(BuildContext context, List<Vehicle> alerts) {
    final bool hasUrgentAlarms = alerts.any(
      (v) => v.isWofExpired || v.isRegoExpired,
    );
    final bool hasUpcomingAlerts = alerts.any(
      (v) => v.isWofExpiringSoon || v.isRegoExpiringSoon || v.isServiceDueSoon,
    );

    if (hasUrgentAlarms) {
      return FloatingActionButton.extended(
        onPressed: () => _handleFeatureTap(
          UsageService.featureManageVehicles,
          const VehiclesScreen(),
        ),
        backgroundColor: const Color(0xFFFF5252),
        icon: Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text(
          'FIX ALERTS',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (hasUpcomingAlerts) {
      return FloatingActionButton.extended(
        onPressed: () => _handleFeatureTap(
          UsageService.featureNewInspection,
          const InspectionFormScreen(),
        ),
        backgroundColor: const Color(0xFFFF9800),
        icon: Icon(Icons.speed, color: Colors.white),
        label: Text(
          'DUE SOON: SCAN',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _handleFeatureTap(
        UsageService.featureNewInspection,
        const InspectionFormScreen(),
      ),
      backgroundColor: const Color(0xFF4FC3F7),
      icon: Icon(Icons.speed, color: Colors.white),
      label: FittedBox(
        child: Text(
          'Speed Check',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class CarbonFiberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const step = 4.0;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.width + size.height; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeedometerPainter extends CustomPainter {
  final double value; // 0.0 to 1.0

  SpeedometerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF4FC3F7), Color(0xFFFF5252), Color(0xFF4FC3F7)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.8,
      math.pi * 1.4,
      false,
      bgPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.8,
      math.pi * 1.4 * value,
      false,
      progressPaint,
    );

    // Needle
    final needleAngle = math.pi * 0.8 + (math.pi * 1.4 * value);
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      center +
          Offset(math.cos(needleAngle), math.sin(needleAngle)) * (radius - 15),
      needlePaint,
    );

    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(SpeedometerPainter oldDelegate) =>
      oldDelegate.value != value;
}
