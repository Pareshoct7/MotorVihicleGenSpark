import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/notification_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const NotificationSettingsScreen({super.key, required this.vehicle});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationSettings _settings;
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _settings = DatabaseService.getOrCreateNotificationSettings(
      widget.vehicle.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car,
                          size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.registrationNo,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.vehicle.make != null ||
                                widget.vehicle.model != null)
                              Text(
                                '${widget.vehicle.make ?? ''} ${widget.vehicle.model ?? ''}'
                                    .trim(),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // WOF Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'WOF Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Enable WOF Reminders'),
                    subtitle: const Text('Get notified before WOF expires'),
                    value: _settings.wofNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings.wofNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),

                  if (_settings.wofNotificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('1 day'),
                            selected: _settings.wofDaysBefore == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.wofDaysBefore = 1;
                                  _settings.customWofNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('1 week'),
                            selected: _settings.wofDaysBefore == 7,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.wofDaysBefore = 7;
                                  _settings.customWofNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('30 days'),
                            selected: _settings.wofDaysBefore == 30,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.wofDaysBefore = 30;
                                  _settings.customWofNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Custom Date'),
                      subtitle: Text(
                        _settings.customWofNotificationDate != null
                            ? dateFormat.format(
                                _settings.customWofNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _settings.customWofNotificationDate ??
                                  DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: widget.vehicle.wofExpiryDate ??
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _settings.customWofNotificationDate = date;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rego Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Registration Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Enable Rego Reminders'),
                    subtitle: const Text('Get notified before registration expires'),
                    value: _settings.regoNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings.regoNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),

                  if (_settings.regoNotificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('1 day'),
                            selected: _settings.regoDaysBefore == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.regoDaysBefore = 1;
                                  _settings.customRegoNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('1 week'),
                            selected: _settings.regoDaysBefore == 7,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.regoDaysBefore = 7;
                                  _settings.customRegoNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('30 days'),
                            selected: _settings.regoDaysBefore == 30,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.regoDaysBefore = 30;
                                  _settings.customRegoNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Custom Date'),
                      subtitle: Text(
                        _settings.customRegoNotificationDate != null
                            ? dateFormat.format(
                                _settings.customRegoNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _settings.customRegoNotificationDate ??
                                  DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: widget.vehicle.regoExpiryDate ??
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _settings.customRegoNotificationDate = date;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    await DatabaseService.saveNotificationSettings(_settings);
    
    // Schedule notifications
    await NotificationService().scheduleWofReminder(widget.vehicle, _settings);
    await NotificationService().scheduleRegoReminder(widget.vehicle, _settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }
}
