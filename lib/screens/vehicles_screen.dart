import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import 'ai_scanner_overlay.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  final List<Animation<double>> _staggeredAnimations = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 10; i++) {
      _staggeredAnimations.add(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(
            i * 0.1,
            0.6 + (i * 0.04),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var vehicles = DatabaseService.getAllVehicles();
    if (_searchQuery.isNotEmpty) {
      vehicles = vehicles
          .where(
            (v) =>
                v.registrationNo.toUpperCase().contains(_searchQuery) ||
                (v.make?.toUpperCase().contains(_searchQuery) ?? false) ||
                (v.model?.toUpperCase().contains(_searchQuery) ?? false),
          )
          .toList();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: Navigator.canPop(context) ? const BackButton() : null,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            title: Text('GARAGE'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toUpperCase()),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'SEARCH RIG...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4FC3F7)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF4FC3F7),
                        ),
                        onPressed: _scanPlate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showVehicleDialog(context),
                icon: Icon(Icons.add_circle_outline, size: 28),
              ),
              const SizedBox(width: 8),
            ],
          ),
          vehicles.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'YOUR GARAGE IS EMPTY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showVehicleDialog(context),
                          icon: Icon(Icons.add),
                          label: Text('ADD FIRST VEHICLE'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final vehicle = vehicles[index];
                      final animation =
                          _staggeredAnimations[math.min(index, 9)];
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ),
                          ),
                          child: _buildVehicleCard(context, vehicle),
                        ),
                      );
                    }, childCount: vehicles.length),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _scanPlate() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const AiScannerView(mode: 'plate'),
      ),
    );
    if (result != null) {
      setState(() {
        _searchQuery = result.toUpperCase();
        _searchController.text = _searchQuery;
      });
    }
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final hasAlerts =
        vehicle.isWofExpired ||
        vehicle.isRegoExpired ||
        vehicle.isServiceOverdue ||
        vehicle.isTyreCheckOverdue;

    final expiringSoon =
        vehicle.isWofExpiringSoon ||
        vehicle.isRegoExpiringSoon ||
        vehicle.isServiceDueSoon ||
        vehicle.isTyreCheckDueSoon;

    final Color statusColor = hasAlerts
        ? const Color(0xFFFF5252)
        : expiringSoon
        ? Colors.orangeAccent
        : const Color(0xFF4FC3F7);

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.registrationNo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                            .trim()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAlerts)
                  Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildStatusRow(
                  'WOF',
                  vehicle.wofExpiryDate != null
                      ? dateFormat.format(vehicle.wofExpiryDate!)
                      : 'NOT SET',
                  vehicle.isWofExpired
                      ? const Color(0xFFFF5252)
                      : (vehicle.isWofExpiringSoon
                            ? Colors.orangeAccent
                            : Colors.white70),
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  'REGO',
                  vehicle.regoExpiryDate != null
                      ? dateFormat.format(vehicle.regoExpiryDate!)
                      : 'NOT SET',
                  vehicle.isRegoExpired
                      ? const Color(0xFFFF5252)
                      : (vehicle.isRegoExpiringSoon
                            ? Colors.orangeAccent
                            : Colors.white70),
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  'SERVICE',
                  vehicle.serviceDueDate != null
                      ? dateFormat.format(vehicle.serviceDueDate!)
                      : 'NOT SET',
                  vehicle.isServiceOverdue
                      ? const Color(0xFFFF5252)
                      : (vehicle.isServiceDueSoon
                            ? Colors.orangeAccent
                            : Colors.white70),
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  'TYRES',
                  vehicle.tyreCheckDate != null
                      ? dateFormat.format(vehicle.tyreCheckDate!)
                      : 'NOT SET',
                  vehicle.isTyreCheckOverdue
                      ? const Color(0xFFFF5252)
                      : (vehicle.isTyreCheckDueSoon
                            ? Colors.orangeAccent
                            : Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _showVehicleDialog(context, vehicle: vehicle),
                  icon: Icon(Icons.tune, size: 18),
                  label: Text('TUNE'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteVehicle(context, vehicle),
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('SCRAP'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.toUpperCase(),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  void _showVehicleDialog(BuildContext context, {Vehicle? vehicle}) {
    showDialog(
      context: context,
      builder: (context) =>
          VehicleDialog(vehicle: vehicle, onSave: () => setState(() {})),
    );
  }

  void _deleteVehicle(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete ${vehicle.registrationNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
            child: Text('Delete'),
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
  late TextEditingController _odometerController;

  DateTime? _wofExpiryDate;
  DateTime? _regoExpiryDate;
  DateTime? _serviceDueDate;
  DateTime? _tyreCheckDate;
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _regNoController = TextEditingController(
      text: widget.vehicle?.registrationNo,
    );
    _makeController = TextEditingController(text: widget.vehicle?.make);
    _modelController = TextEditingController(text: widget.vehicle?.model);
    _yearController = TextEditingController(
      text: widget.vehicle?.year?.toString(),
    );
    _odometerController = TextEditingController(
      text: widget.vehicle?.odometerReading?.toString(),
    );
    _wofExpiryDate = widget.vehicle?.wofExpiryDate;
    _regoExpiryDate = widget.vehicle?.regoExpiryDate;
    _serviceDueDate = widget.vehicle?.serviceDueDate;
    _tyreCheckDate = widget.vehicle?.tyreCheckDate;
    _selectedStoreId = widget.vehicle?.storeId;
  }

  @override
  Widget build(BuildContext context) {
    final stores = DatabaseService.getAllStores();
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.vehicle == null ? 'NEW RIG' : 'TUNE RIG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _regNoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'REGISTRATION NO',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'REQUIRED' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _makeController,
                        decoration: InputDecoration(labelText: 'MAKE'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(labelText: 'MODEL'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: InputDecoration(labelText: 'YEAR'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _odometerController,
                        decoration: InputDecoration(
                          labelText: 'ODOMETER',
                          suffixText: 'KM',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStoreId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'BASE HUB',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  dropdownColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  items: stores.map((store) {
                    return DropdownMenuItem(
                      value: store.id,
                      child: Text(
                        store.name.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStoreId = value),
                ),
                const SizedBox(height: 24),
                Text(
                  'MAINTENANCE LOGS',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDatePickerTile(
                  'WOF EXPIRY',
                  _wofExpiryDate,
                  (date) => setState(() => _wofExpiryDate = date),
                  dateFormat,
                ),
                const SizedBox(height: 12),
                _buildDatePickerTile(
                  'REGISTRATION EXPIRY',
                  _regoExpiryDate,
                  (date) => setState(() => _regoExpiryDate = date),
                  dateFormat,
                ),
                const SizedBox(height: 12),
                _buildDatePickerTile(
                  'NEXT SERVICE',
                  _serviceDueDate,
                  (date) => setState(() => _serviceDueDate = date),
                  dateFormat,
                ),
                const SizedBox(height: 12),
                _buildDatePickerTile(
                  'TYRE CHECK',
                  _tyreCheckDate,
                  (date) => setState(() => _tyreCheckDate = date),
                  dateFormat,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveVehicle,
                  child: Text(
                    widget.vehicle == null ? 'ADD TO GARAGE' : 'SAVE TUNING',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(
    String label,
    DateTime? value,
    Function(DateTime) onSelected,
    DateFormat format,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
        );
        if (date != null) onSelected(date);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value != null ? format.format(value).toUpperCase() : 'SET DATE',
              style: TextStyle(
                color: value != null ? const Color(0xFF4FC3F7) : Colors.white24,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newOdometerReading = _odometerController.text.isNotEmpty
        ? int.tryParse(_odometerController.text)
        : null;

    DateTime? odometerUpdatedAt = widget.vehicle?.odometerUpdatedAt;

    // Update timestamp if odometer changed or is being set for the first time
    if (newOdometerReading != widget.vehicle?.odometerReading) {
      if (newOdometerReading != null) {
        odometerUpdatedAt = DateTime.now();
      }
    }

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      registrationNo: _regNoController.text,
      make: _makeController.text.isNotEmpty ? _makeController.text : null,
      model: _modelController.text.isNotEmpty ? _modelController.text : null,
      year: _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null,
      odometerReading: newOdometerReading,
      odometerUpdatedAt: odometerUpdatedAt,
      wofExpiryDate: _wofExpiryDate,
      regoExpiryDate: _regoExpiryDate,
      serviceDueDate: _serviceDueDate,
      tyreCheckDate: _tyreCheckDate,
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
    final settings = DatabaseService.getOrCreateNotificationSettings(
      vehicle.id,
    );
    await NotificationService().scheduleWofReminder(vehicle, settings);
    await NotificationService().scheduleRegoReminder(vehicle, settings);
    await NotificationService().scheduleServiceReminder(vehicle, settings);
    await NotificationService().scheduleTyreCheckReminder(vehicle, settings);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }
}
