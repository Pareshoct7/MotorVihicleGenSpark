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
        padding: EdgeInsets.all(16),
        children: [
          // Vehicle Info
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
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
                              style: TextStyle(
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
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
                    title: Text('Enable WOF Reminders'),
                    subtitle: Text('Get notified before WOF expires'),
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
                      title: Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: Text('1 day'),
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
                            label: Text('1 week'),
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
                            label: Text('30 days'),
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
                      title: Text('Custom Date'),
                      subtitle: Text(
                        _settings.customWofNotificationDate != null
                            ? dateFormat.format(
                                _settings.customWofNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: Icon(Icons.calendar_today),
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
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
                    title: Text('Enable Rego Reminders'),
                    subtitle: Text('Get notified before registration expires'),
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
                      title: Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: Text('1 day'),
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
                            label: Text('1 week'),
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
                            label: Text('30 days'),
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
                      title: Text('Custom Date'),
                      subtitle: Text(
                        _settings.customRegoNotificationDate != null
                            ? dateFormat.format(
                                _settings.customRegoNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: Icon(Icons.calendar_today),
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

          const SizedBox(height: 16),

          // Service Notifications
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Service Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text('Enable Service Reminders'),
                    subtitle: Text('Get notified before service is due'),
                    value: _settings.serviceNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings.serviceNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),

                  if (_settings.serviceNotificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: Text('1 day'),
                            selected: _settings.serviceDaysBefore == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.serviceDaysBefore = 1;
                                  _settings.customServiceNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('1 week'),
                            selected: _settings.serviceDaysBefore == 7,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.serviceDaysBefore = 7;
                                  _settings.customServiceNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('30 days'),
                            selected: _settings.serviceDaysBefore == 30,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.serviceDaysBefore = 30;
                                  _settings.customServiceNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('Custom Date'),
                      subtitle: Text(
                        _settings.customServiceNotificationDate != null
                            ? dateFormat.format(
                                _settings.customServiceNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _settings.customServiceNotificationDate ??
                                  DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: widget.vehicle.serviceDueDate ??
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _settings.customServiceNotificationDate = date;
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

          // Tyre Check Notifications
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tire_repair,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tyre Check Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text('Enable Tyre Check Reminders'),
                    subtitle: Text('Get notified before tyre check is due'),
                    value: _settings.tyreNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings.tyreNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),

                  if (_settings.tyreNotificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: Text('Notify me'),
                      subtitle: Row(
                        children: [
                          ChoiceChip(
                            label: Text('1 day'),
                            selected: _settings.tyreDaysBefore == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.tyreDaysBefore = 1;
                                  _settings.customTyreNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('1 week'),
                            selected: _settings.tyreDaysBefore == 7,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.tyreDaysBefore = 7;
                                  _settings.customTyreNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('30 days'),
                            selected: _settings.tyreDaysBefore == 30,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _settings.tyreDaysBefore = 30;
                                  _settings.customTyreNotificationDate = null;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('Custom Date'),
                      subtitle: Text(
                        _settings.customTyreNotificationDate != null
                            ? dateFormat.format(
                                _settings.customTyreNotificationDate!)
                            : 'Not set',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _settings.customTyreNotificationDate ??
                                  DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: widget.vehicle.tyreCheckDate ??
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _settings.customTyreNotificationDate = date;
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
    await NotificationService().scheduleServiceReminder(widget.vehicle, _settings);
    await NotificationService().scheduleTyreCheckReminder(widget.vehicle, _settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }
}
