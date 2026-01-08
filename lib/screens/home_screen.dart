import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'introduction_screen.dart';
import 'about_developer_screen.dart';
import 'offline_drive_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _topFeatures = [];
  bool _isLoadingUsage = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
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
    final vehiclesNeedingAttention = DatabaseService.getVehiclesNeedingAttention();
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
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                _getGreeting(),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
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
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ).then((_) => setState(() {})),
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Stats
                  _buildDashboard(context, allInspections.length),

                  const SizedBox(height: 32),

                  // Smart Suggestions / Alerts
                  if (vehiclesNeedingAttention.isNotEmpty)
                    _buildAlertsSection(context, vehiclesNeedingAttention),

                  const SizedBox(height: 32),

                  // Dynamic Top Actions
                  Text(
                    'Top Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingUsage
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDynamicActions(),

                  const SizedBox(height: 16),
                  
                  // Secondary Actions (Horizontal Scroll)
                  _buildSecondaryActions(),

                  const SizedBox(height: 32),

                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Inspections',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InspectionHistoryScreen()),
                        ).then((_) => setState(() {})),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentInspections.isEmpty)
                    _buildEmptyState()
                  else
                    ...recentInspections.map((i) => _buildRecentInspectionItem(context, i)),
                  
                  const SizedBox(height: 100), // Space for bottom
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleFeatureTap(
          UsageService.featureNewInspection,
          const InspectionFormScreen(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, int totalInspections) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fleet Status',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalInspections Reports',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _handleFeatureTap(
                    UsageService.featureReportsAnalytics,
                    const ReportsScreen(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'View Analytics',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 40),
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
            const Icon(Icons.notification_important, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'ATTENTION REQUIRED',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.registrationNo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.isWofExpired ? 'WOF Expired' : 'Rego Expired',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
        childAspectRatio: 1.5,
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
        );
      },
    );
  }

  Widget _buildSecondaryActions() {
    final unusedFeatures = UsageService.allFeatures
        .where((f) => !_topFeatures.contains(f))
        .toList();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: unusedFeatures.length,
        itemBuilder: (context, index) {
          final featureId = unusedFeatures[index];
          final meta = UsageService.getFeatureMeta(featureId);
          return GestureDetector(
            onTap: () => _handleFeatureTap(featureId, _getFeatureScreen(featureId)),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      IconData(meta['icon'], fontFamily: 'MaterialIcons'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meta['title'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
  ) {
    return InkWell(
      onTap: () => _handleFeatureTap(featureId, screen),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildRecentInspectionItem(BuildContext context, Inspection inspection) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.assignment_outlined, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          inspection.vehicleRegistrationNo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('By ${inspection.employeeName} • ${inspection.storeName}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateFormat.format(inspection.inspectionDate),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
            const Icon(Icons.chevron_right, size: 16),
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No recent inspections found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 30,
                  child: Icon(Icons.local_pizza, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vehicle Inspection',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _buildDrawerItem(context, 'New Inspection', Icons.add_task, UsageService.featureNewInspection, const InspectionFormScreen()),
          _buildDrawerItem(context, 'History', Icons.history, 'history', const InspectionHistoryScreen()),
          _buildDrawerItem(context, 'Offline Drive', Icons.folder_shared_outlined, UsageService.featureOfflineDrive, const OfflineDriveScreen()),
          const Divider(),
          _buildDrawerItem(context, 'Bulk Reports', Icons.auto_awesome_outlined, UsageService.featureBulkReports, const BulkReportsScreen()),
          _buildDrawerItem(context, 'Analytics', Icons.assessment_outlined, UsageService.featureReportsAnalytics, const ReportsScreen()),
          const Divider(),
          _buildDrawerItem(context, 'Vehicles', Icons.directions_car_outlined, UsageService.featureManageVehicles, const VehiclesScreen()),
          _buildDrawerItem(context, 'Stores', Icons.store_outlined, UsageService.featureManageStores, const StoresScreen()),
          _buildDrawerItem(context, 'Drivers', Icons.person_outline, UsageService.featureManageDrivers, const DriversScreen()),
          const Divider(),
          _buildDrawerItem(context, 'Reminders', Icons.notification_important_outlined, UsageService.featureReminders, const RemindersScreen()),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
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

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String featureId, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
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
}
