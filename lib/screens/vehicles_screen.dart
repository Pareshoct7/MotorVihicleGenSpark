import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

import '../services/notification_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vehicles yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(context, vehicle);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showVehicleDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasAlerts =
        vehicle.isWofExpired ||
        vehicle.isWofExpiringSoon ||
        vehicle.isRegoExpired ||
        vehicle.isRegoExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: hasAlerts ? Colors.red.shade50 : null,
      child: ExpansionTile(
        leading: Icon(
          Icons.directions_car,
          color: hasAlerts ? Colors.red.shade700 : Colors.blue,
          size: 32,
        ),
        title: Text(
          vehicle.registrationNo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: vehicle.make != null || vehicle.model != null
            ? Text('${vehicle.make ?? ''} ${vehicle.model ?? ''}'.trim())
            : null,
        trailing: hasAlerts
            ? Icon(Icons.warning, color: Colors.red.shade700)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicle.year != null)
                  _buildInfoRow('Year', vehicle.year.toString()),
                
                const Divider(height: 24),
                
                // WOF Information
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
                    const Text(
                      'WOF:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicle.wofExpiryDate != null
                            ? dateFormat.format(vehicle.wofExpiryDate!)
                            : 'Not set',
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
                      Chip(
                        label: const Text(
                          'EXPIRED',
                          style: TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.red,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    else if (vehicle.isWofExpiringSoon)
                      Chip(
                        label: Text(
                          '${vehicle.wofExpiryDate!.difference(DateTime.now()).inDays} days',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.orange,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Registration Information
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
                    const Text(
                      'Registration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicle.regoExpiryDate != null
                            ? dateFormat.format(vehicle.regoExpiryDate!)
                            : 'Not set',
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
                      Chip(
                        label: const Text(
                          'EXPIRED',
                          style: TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.red,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    else if (vehicle.isRegoExpiringSoon)
                      Chip(
                        label: Text(
                          '${vehicle.regoExpiryDate!.difference(DateTime.now()).inDays} days',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.orange,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                
                const Divider(height: 24),
                
                if (vehicle.storeId != null) ...[
                  _buildInfoRow(
                    'Store',
                    DatabaseService.getStore(vehicle.storeId!)?.name ?? 'Unknown',
                  ),
                  const SizedBox(height: 8),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showVehicleDialog(context, vehicle: vehicle);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _deleteVehicle(context, vehicle);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  void _showVehicleDialog(BuildContext context, {Vehicle? vehicle}) {
    showDialog(
      context: context,
      builder: (context) => VehicleDialog(
        vehicle: vehicle,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _deleteVehicle(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete ${vehicle.registrationNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteVehicle(vehicle.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle deleted')),
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

class VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;
  final VoidCallback onSave;

  const VehicleDialog({super.key, this.vehicle, required this.onSave});

  @override
  State<VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _regNoController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  
  DateTime? _wofExpiryDate;
  DateTime? _regoExpiryDate;
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _regNoController = TextEditingController(text: widget.vehicle?.registrationNo);
    _makeController = TextEditingController(text: widget.vehicle?.make);
    _modelController = TextEditingController(text: widget.vehicle?.model);
    _yearController = TextEditingController(
      text: widget.vehicle?.year?.toString(),
    );
    _wofExpiryDate = widget.vehicle?.wofExpiryDate;
    _regoExpiryDate = widget.vehicle?.regoExpiryDate;
    _selectedStoreId = widget.vehicle?.storeId;
  }

  @override
  Widget build(BuildContext context) {
    final stores = DatabaseService.getAllStores();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _regNoController,
                decoration: const InputDecoration(
                  labelText: 'Registration No *',
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
                controller: _makeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStoreId,
                decoration: const InputDecoration(
                  labelText: 'Store',
                  border: OutlineInputBorder(),
                ),
                items: stores.map((store) {
                  return DropdownMenuItem(
                    value: store.id,
                    child: Text(store.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStoreId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _wofExpiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _wofExpiryDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'WOF Expiry Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _wofExpiryDate != null
                        ? dateFormat.format(_wofExpiryDate!)
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _regoExpiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _regoExpiryDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Registration Expiry Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _regoExpiryDate != null
                        ? dateFormat.format(_regoExpiryDate!)
                        : 'Select date',
                  ),
                ),
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
          onPressed: _saveVehicle,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      registrationNo: _regNoController.text,
      make: _makeController.text.isNotEmpty ? _makeController.text : null,
      model: _modelController.text.isNotEmpty ? _modelController.text : null,
      year: _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null,
      wofExpiryDate: _wofExpiryDate,
      regoExpiryDate: _regoExpiryDate,
      storeId: _selectedStoreId,
      createdAt: widget.vehicle?.createdAt,
    );

    if (widget.vehicle != null) {
      await DatabaseService.updateVehicle(vehicle);
    } else {
      await DatabaseService.addVehicle(vehicle);
      
      // Auto-set as default if this is the first vehicle
      final allVehicles = DatabaseService.getAllVehicles();
      if (allVehicles.length == 1) {
        await PreferencesService.setDefaultVehicle(vehicle.id);
      }
    }

    // Schedule notifications
    final settings = DatabaseService.getOrCreateNotificationSettings(vehicle.id);
    await NotificationService().scheduleWofReminder(vehicle, settings);
    await NotificationService().scheduleRegoReminder(vehicle, settings);

    if (mounted) {
      widget.onSave();
      Navigator.pop(context);
      
      // Show appropriate message
      final allVehicles = DatabaseService.getAllVehicles();
      String message;
      if (widget.vehicle != null) {
        message = 'Vehicle updated';
      } else if (allVehicles.length == 1) {
        message = 'Vehicle added and set as default';
      } else {
        message = 'Vehicle added';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
