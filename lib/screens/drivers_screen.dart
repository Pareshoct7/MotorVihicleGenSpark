import 'dart:math' as math;
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

class _DriversScreenState extends State<DriversScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  final List<Animation<double>> _staggeredAnimations = [];

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
          curve: Interval(i * 0.1, 0.6 + (i * 0.04), curve: Curves.easeOutCubic),
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
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: Navigator.canPop(context) ? const BackButton() : null,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            title: const Text('DRIVERS'),
            actions: [
              IconButton(
                onPressed: () => _showDriverDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 28),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drivers.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outlined,
                          size: 80,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ROSTER IS EMPTY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showDriverDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('ADD DRIVER'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final driver = drivers[index];
                        final animation = _staggeredAnimations[math.min(index, 9)];
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: animation.drive(
                              Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero),
                            ),
                            child: _buildDriverCard(context, driver),
                          ),
                        );
                      },
                      childCount: drivers.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, Driver driver) {
    const accentColor = Color(0xFF4FC3F7); // Driver theme color

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, color: accentColor),
        ),
        title: Text(
          driver.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (driver.licenseNumber != null)
              Text(
                'LICENSE: ${driver.licenseNumber!.toUpperCase()}',
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            if (driver.phone != null || driver.email != null)
              Text(
                '${driver.phone ?? ''} ${driver.email ?? ''}'.trim(),
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white30),
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18),
                  SizedBox(width: 12),
                  Text('EDIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5252)),
                  SizedBox(width: 12),
                  Text('DELETE', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 12)),
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
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                      widget.driver == null ? 'ADD DRIVER' : 'EDIT DRIVER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'DRIVER FULL NAME',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'REQUIRED' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licenseController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'LICENSE NUMBER',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'CONTACT PHONE',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'EMAIL ADDRESS',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveDriver,
                  child: Text(widget.driver == null ? 'SAVE DRIVER' : 'UPDATE DRIVER'),
                ),
              ],
            ),
          ),
        ),
      ),
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
