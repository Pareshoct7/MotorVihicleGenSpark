import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/data_backup_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _defaultVehicleId;
  String? _defaultStoreId;
  String? _defaultDriverId;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final vehicleId = await PreferencesService.getDefaultVehicle();
    final storeId = await PreferencesService.getDefaultStore();
    final driverId = await PreferencesService.getDefaultDriver();

    setState(() {
      _defaultVehicleId = vehicleId;
      _defaultStoreId = storeId;
      _defaultDriverId = driverId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Theme Selection Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize app appearance',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return DropdownButtonFormField<ThemeMode>(
                        value: themeProvider.themeMode,
                        decoration: InputDecoration(
                          labelText: 'Theme Mode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.palette),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System Default'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Theme updated'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Default Selections Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Selections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set default values for new inspections',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Default Vehicle
                  DropdownButtonFormField<String>(
                    value: _defaultVehicleId,
                    decoration: InputDecoration(
                      labelText: 'Default Vehicle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(vehicle.registrationNo),
                        );
                      }),
                    ],
                    onChanged: (value) async {
                      await PreferencesService.setDefaultVehicle(value);
                      setState(() {
                        _defaultVehicleId = value;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Default vehicle updated'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Default Store
                  DropdownButtonFormField<String>(
                    value: _defaultStoreId,
                    decoration: InputDecoration(
                      labelText: 'Default Store',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...stores.map((store) {
                        return DropdownMenuItem(
                          value: store.id,
                          child: Text(store.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) async {
                      await PreferencesService.setDefaultStore(value);
                      setState(() {
                        _defaultStoreId = value;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Default store updated'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Default Driver
                  DropdownButtonFormField<String>(
                    value: _defaultDriverId,
                    decoration: InputDecoration(
                      labelText: 'Default Driver/Employee',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...drivers.map((driver) {
                        return DropdownMenuItem(
                          value: driver.id,
                          child: Text(driver.name),
                        );
                      }),
                    ],
                    onChanged: (value) async {
                      await PreferencesService.setDefaultDriver(value);
                      setState(() {
                        _defaultDriverId = value;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Default driver updated'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Backup and restore your data',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await DataBackupService.exportDatabase();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Database exported successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export failed: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.upload_file),
                      label: Text('Export Database'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final success = await DataBackupService.importDatabase();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Database imported successfully')),
                            );
                            // Refresh UI if needed, though Hive updates should be reactive if using ValueListenableBuilder
                            // But here we might want to reload defaults if they were overwritten
                            _loadDefaults(); 
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Import failed: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.download),
                      label: Text('Import Database'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
