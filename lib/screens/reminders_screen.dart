import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import 'vehicles_screen.dart';
import 'notification_settings_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final allVehicles = DatabaseService.getAllVehicles();
    final vehiclesWithReminders = allVehicles.where((v) {
      return v.wofExpiryDate != null || v.regoExpiryDate != null;
    }).toList();

    final expiredVehicles = vehiclesWithReminders.where((v) {
      return v.isWofExpired || v.isRegoExpired;
    }).toList();

    final expiringVehicles = vehiclesWithReminders.where((v) {
      return (v.isWofExpiringSoon && !v.isWofExpired) ||
          (v.isRegoExpiringSoon && !v.isRegoExpired);
    }).toList();

    final upcomingVehicles = vehiclesWithReminders.where((v) {
      return !v.isWofExpired &&
          !v.isWofExpiringSoon &&
          !v.isRegoExpired &&
          !v.isRegoExpiringSoon;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('WOF & Rego Reminders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: vehiclesWithReminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notification_important_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders set',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add WOF/Rego dates to vehicles',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Expired Section
                if (expiredVehicles.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'EXPIRED',
                    expiredVehicles.length,
                    Colors.red,
                  ),
                  ...expiredVehicles.map((vehicle) {
                    return _buildReminderCard(context, vehicle, Colors.red);
                  }),
                  const SizedBox(height: 16),
                ],

                // Expiring Soon Section
                if (expiringVehicles.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'EXPIRING SOON (30 days)',
                    expiringVehicles.length,
                    Colors.orange,
                  ),
                  ...expiringVehicles.map((vehicle) {
                    return _buildReminderCard(context, vehicle, Colors.orange);
                  }),
                  const SizedBox(height: 16),
                ],

                // Upcoming Section
                if (upcomingVehicles.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'UPCOMING',
                    upcomingVehicles.length,
                    Colors.green,
                  ),
                  ...upcomingVehicles.map((vehicle) {
                    return _buildReminderCard(context, vehicle, Colors.green);
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Vehicle vehicle,
    Color color,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicle.registrationNo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationSettingsScreen(
                          vehicle: vehicle,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  tooltip: 'Notification Settings',
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehiclesScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  tooltip: 'Edit Vehicle',
                ),
              ],
            ),
            if (vehicle.make != null || vehicle.model != null) ...[
              const SizedBox(height: 4),
              Text(
                '${vehicle.make ?? ''} ${vehicle.model ?? ''}'.trim(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
            const Divider(height: 24),

            // WOF Status
            if (vehicle.wofExpiryDate != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 20,
                    color: vehicle.isWofExpired
                        ? Colors.red
                        : vehicle.isWofExpiringSoon
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WOF:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormat.format(vehicle.wofExpiryDate!),
                      style: TextStyle(
                        color: vehicle.isWofExpired
                            ? Colors.red
                            : vehicle.isWofExpiringSoon
                                ? Colors.orange
                                : null,
                      ),
                    ),
                  ),
                  if (vehicle.isWofExpired)
                    const Chip(
                      label: Text(
                        'EXPIRED',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )
                  else if (vehicle.isWofExpiringSoon)
                    Chip(
                      label: Text(
                        '${vehicle.wofExpiryDate!.difference(DateTime.now()).inDays} days',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Rego Status
            if (vehicle.regoExpiryDate != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 20,
                    color: vehicle.isRegoExpired
                        ? Colors.red
                        : vehicle.isRegoExpiringSoon
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Registration:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormat.format(vehicle.regoExpiryDate!),
                      style: TextStyle(
                        color: vehicle.isRegoExpired
                            ? Colors.red
                            : vehicle.isRegoExpiringSoon
                                ? Colors.orange
                                : null,
                      ),
                    ),
                  ),
                  if (vehicle.isRegoExpired)
                    const Chip(
                      label: Text(
                        'EXPIRED',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )
                  else if (vehicle.isRegoExpiringSoon)
                    Chip(
                      label: Text(
                        '${vehicle.regoExpiryDate!.difference(DateTime.now()).inDays} days',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
