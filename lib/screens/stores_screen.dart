import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/store.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> with SingleTickerProviderStateMixin {
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
    final stores = DatabaseService.getAllStores();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: Navigator.canPop(context) ? const BackButton() : null,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            title: const Text('STORES'),
            actions: [
              IconButton(
                onPressed: () => _showStoreDialog(context),
                icon: const Icon(Icons.add_business_outlined, size: 28),
              ),
              const SizedBox(width: 8),
            ],
          ),
          stores.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 80,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'NO STORES REGISTERED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showStoreDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('ADD STORE'),
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
                        final store = stores[index];
                        final animation = _staggeredAnimations[math.min(index, 9)];
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: animation.drive(
                              Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero),
                            ),
                            child: _buildStoreCard(context, store),
                          ),
                        );
                      },
                      childCount: stores.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, Store store) {
    const accentColor = Color(0xFFAB47BC); // Store theme color

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
          child: const Icon(Icons.store, color: accentColor),
        ),
        title: Text(
          store.displayName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (store.address != null)
              Text(
                store.address!.toUpperCase(),
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            if (store.phone != null)
              Text(
                store.phone!,
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
              _showStoreDialog(context, store: store);
            } else if (value == 'delete') {
              _deleteStore(context, store);
            }
          },
        ),
      ),
    );
  }

  void _showStoreDialog(BuildContext context, {Store? store}) {
    showDialog(
      context: context,
      builder: (context) => StoreDialog(
        store: store,
        onSave: () => setState(() {}),
      ),
    );
  }

  void _deleteStore(BuildContext context, Store store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete ${store.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteStore(store.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Store deleted')),
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

class StoreDialog extends StatefulWidget {
  final Store? store;
  final VoidCallback onSave;

  const StoreDialog({super.key, this.store, required this.onSave});

  @override
  State<StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<StoreDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _storeNumberController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store?.name);
    _storeNumberController = TextEditingController(text: widget.store?.storeNumber);
    _addressController = TextEditingController(text: widget.store?.address);
    _phoneController = TextEditingController(text: widget.store?.phone);
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
                      widget.store == null ? 'ADD STORE' : 'EDIT STORE',
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
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'STORE NAME',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'REQUIRED' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _storeNumberController,
                  decoration: const InputDecoration(
                    labelText: 'STORE ID / NUMBER',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'ADDRESS',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveStore,
                  child: Text(widget.store == null ? 'SAVE STORE' : 'UPDATE STORE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _saveStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = Store(
      id: widget.store?.id ?? const Uuid().v4(),
      name: _nameController.text,
      storeNumber: _storeNumberController.text.isNotEmpty ? _storeNumberController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      createdAt: widget.store?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.store != null) {
      await DatabaseService.updateStore(store);
    } else {
      await DatabaseService.addStore(store);
      
      // Auto-set as default if this is the first store
      final allStores = DatabaseService.getAllStores();
      if (allStores.length == 1) {
        await PreferencesService.setDefaultStore(store.id);
      }
    }

    if (mounted) {
      widget.onSave();
      Navigator.pop(context);
      
      // Show appropriate message
      final allStores = DatabaseService.getAllStores();
      String message;
      if (widget.store != null) {
        message = 'Store updated';
      } else if (allStores.length == 1) {
        message = 'Store added and set as default';
      } else {
        message = 'Store added';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
