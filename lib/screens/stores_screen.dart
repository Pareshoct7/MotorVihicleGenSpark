import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/store.dart';
import '../services/database_service.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  Widget build(BuildContext context) {
    final stores = DatabaseService.getAllStores();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stores'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: stores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stores yet',
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
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.store),
                    ),
                    title: Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (store.address != null)
                          Text(store.address!),
                        if (store.phone != null)
                          Text(store.phone!),
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
                          _showStoreDialog(context, store: store);
                        } else if (value == 'delete') {
                          _deleteStore(context, store);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showStoreDialog(context);
        },
        child: const Icon(Icons.add),
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
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store?.name);
    _addressController = TextEditingController(text: widget.store?.address);
    _phoneController = TextEditingController(text: widget.store?.phone);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.store == null ? 'Add Store' : 'Edit Store'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name *',
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
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: _saveStore,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = Store(
      id: widget.store?.id ?? const Uuid().v4(),
      name: _nameController.text,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      createdAt: widget.store?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.store != null) {
      await DatabaseService.updateStore(store);
    } else {
      await DatabaseService.addStore(store);
    }

    if (mounted) {
      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.store != null ? 'Store updated' : 'Store added',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
