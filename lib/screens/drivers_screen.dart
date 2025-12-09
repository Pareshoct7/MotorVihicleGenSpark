import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/driver.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  @override
  Widget build(BuildContext context) {
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: drivers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No drivers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      driver.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (driver.licenseNumber != null)
                          Text('License: ${driver.licenseNumber!}'),
                        if (driver.phone != null)
                          Text('Phone: ${driver.phone!}'),
                        if (driver.email != null)
                          Text('Email: ${driver.email!}'),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showDriverDialog(context, driver: driver);
                        } else if (value == 'delete') {
                          _deleteDriver(context, driver);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDriverDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDriverDialog(BuildContext context, {Driver? driver}) {
    showDialog(
      context: context,
      builder: (context) => DriverDialog(
        driver: driver,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _deleteDriver(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteDriver(driver.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class DriverDialog extends StatefulWidget {
  final Driver? driver;
  final VoidCallback onSave;

  const DriverDialog({super.key, this.driver, required this.onSave});

  @override
  State<DriverDialog> createState() => _DriverDialogState();
}

class _DriverDialogState extends State<DriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _licenseController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver?.name);
    _licenseController = TextEditingController(text: widget.driver?.licenseNumber);
    _phoneController = TextEditingController(text: widget.driver?.phone);
    _emailController = TextEditingController(text: widget.driver?.email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.driver == null ? 'Add Driver' : 'Edit Driver'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveDriver,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final driver = Driver(
      id: widget.driver?.id ?? const Uuid().v4(),
      name: _nameController.text,
      licenseNumber: _licenseController.text.isNotEmpty ? _licenseController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      createdAt: widget.driver?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.driver != null) {
      await DatabaseService.updateDriver(driver);
    } else {
      await DatabaseService.addDriver(driver);
      
      // Auto-set as default if this is the first driver
      final allDrivers = DatabaseService.getAllDrivers();
      if (allDrivers.length == 1) {
        await PreferencesService.setDefaultDriver(driver.id);
      }
    }

    if (mounted) {
      widget.onSave();
      Navigator.pop(context);
      
      // Show appropriate message
      final allDrivers = DatabaseService.getAllDrivers();
      String message;
      if (widget.driver != null) {
        message = 'Driver updated';
      } else if (allDrivers.length == 1) {
        message = 'Driver added and set as default';
      } else {
        message = 'Driver added';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
