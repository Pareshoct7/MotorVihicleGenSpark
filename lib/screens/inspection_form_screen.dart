import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/inspection.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/preferences_service.dart';

class InspectionFormScreen extends StatefulWidget {
  final Inspection? inspection;
  final Inspection? baseInspection;
  final bool isViewOnly;

  const InspectionFormScreen({
    super.key,
    this.inspection,
    this.baseInspection,
    this.isViewOnly = false,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _correctiveActionsController = TextEditingController();
  final _signatureController = TextEditingController();
  final _bodyDamageNotesController = TextEditingController();

  DateTime _inspectionDate = DateTime.now();
  String? _selectedVehicleId;
  String? _selectedStoreId;
  String? _selectedDriverId;

  // Checklist states - Default all to true
  bool? _tyresTreadDepth = true;
  bool? _wheelNuts = true;
  bool? _cleanliness = true;
  bool? _bodyDamage = true;
  bool? _mirrorsWindows = true;
  bool? _signage = true;
  bool? _engineOilWater = true;
  bool? _brakes = true;
  bool? _transmission = true;
  bool? _tailLights = true;
  bool? _headlightsLowBeam = true;
  bool? _headlightsHighBeam = true;
  bool? _reverseLights = true;
  bool? _brakeLights = true;
  bool? _windscreenWipers = true;
  bool? _horn = true;
  bool? _indicators = true;
  bool? _seatBelts = true;
  bool? _cabCleanliness = true;
  bool? _serviceLogBook = true;
  bool? _spareKeys = true;

  @override
  void initState() {
    super.initState();
    if (widget.inspection != null) {
      _loadInspectionData();
    } else if (widget.baseInspection != null) {
      _loadBaseInspectionData();
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() async {
    // Load default vehicle, store, and driver from preferences
    final vehicleId = await PreferencesService.getDefaultVehicle();
    final storeId = await PreferencesService.getDefaultStore();
    final driverId = await PreferencesService.getDefaultDriver();
    
    setState(() {
      _selectedVehicleId = vehicleId;
      _selectedStoreId = storeId;
      _selectedDriverId = driverId;
    });
  }

  void _loadBaseInspectionData() {
    // Load data from base inspection for repeat functionality
    final base = widget.baseInspection!;
    setState(() {
      _selectedVehicleId = base.vehicleId;
      _selectedStoreId = base.storeId;
      _selectedDriverId = base.driverId;
      // Date and odometer are left empty for user to fill
      // All checkboxes remain at default (true)
    });
  }

  void _loadInspectionData() {
    final inspection = widget.inspection!;
    _selectedVehicleId = inspection.vehicleId;
    _selectedStoreId = inspection.storeId;
    _selectedDriverId = inspection.driverId;
    _inspectionDate = inspection.inspectionDate;
    _odometerController.text = inspection.odometerReading;
    _correctiveActionsController.text = inspection.correctiveActions ?? '';
    _signatureController.text = inspection.signature ?? '';
    _bodyDamageNotesController.text = inspection.bodyDamageNotes ?? '';

    _tyresTreadDepth = inspection.tyresTreadDepth;
    _wheelNuts = inspection.wheelNuts;
    _cleanliness = inspection.cleanliness;
    _bodyDamage = inspection.bodyDamage;
    _mirrorsWindows = inspection.mirrorsWindows;
    _signage = inspection.signage;
    _engineOilWater = inspection.engineOilWater;
    _brakes = inspection.brakes;
    _transmission = inspection.transmission;
    _tailLights = inspection.tailLights;
    _headlightsLowBeam = inspection.headlightsLowBeam;
    _headlightsHighBeam = inspection.headlightsHighBeam;
    _reverseLights = inspection.reverseLights;
    _brakeLights = inspection.brakeLights;
    _windscreenWipers = inspection.windscreenWipers;
    _horn = inspection.horn;
    _indicators = inspection.indicators;
    _seatBelts = inspection.seatBelts;
    _cabCleanliness = inspection.cabCleanliness;
    _serviceLogBook = inspection.serviceLogBook;
    _spareKeys = inspection.spareKeys;
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewOnly
              ? 'View Inspection'
              : widget.inspection != null
                  ? 'Edit Inspection'
                  : 'New Inspection',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.inspection != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                await PdfService.shareInspection(widget.inspection!);
              },
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Inspection Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Inspection Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Selection
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Registration No *',
                          border: OutlineInputBorder(),
                        ),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.registrationNo),
                          );
                        }).toList(),
                        onChanged: widget.isViewOnly
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedVehicleId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a vehicle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Store Selection
                      DropdownButtonFormField<String>(
                        value: _selectedStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Store *',
                          border: OutlineInputBorder(),
                        ),
                        items: stores.map((store) {
                          return DropdownMenuItem(
                            value: store.id,
                            child: Text(store.name),
                          );
                        }).toList(),
                        onChanged: widget.isViewOnly
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedStoreId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a store';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _odometerController,
                              decoration: const InputDecoration(
                                labelText: 'Odometer Reading *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              readOnly: widget.isViewOnly,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: widget.isViewOnly
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _inspectionDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _inspectionDate = date;
                                        });
                                      }
                                    },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date *',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_inspectionDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Driver/Employee Selection
                      DropdownButtonFormField<String>(
                        value: _selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Employee Name *',
                          border: OutlineInputBorder(),
                        ),
                        items: drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.id,
                            child: Text(driver.name),
                          );
                        }).toList(),
                        onChanged: widget.isViewOnly
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedDriverId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an employee';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section 2: Inspection Checklist
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Inspection Checklist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Tyres
                      _buildChecklistSection(
                        'Tyres',
                        [
                          _ChecklistItem(
                            'Tyres (tread depth)',
                            _tyresTreadDepth,
                            (val) => setState(() => _tyresTreadDepth = val),
                          ),
                          _ChecklistItem(
                            'Wheel nuts',
                            _wheelNuts,
                            (val) => setState(() => _wheelNuts = val),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Outside
                      _buildChecklistSection(
                        'Outside',
                        [
                          _ChecklistItem(
                            'Cleanliness',
                            _cleanliness,
                            (val) => setState(() => _cleanliness = val),
                          ),
                          _ChecklistItem(
                            'Body damage: scratches/dents etc.',
                            _bodyDamage,
                            (val) => setState(() => _bodyDamage = val),
                          ),
                          _ChecklistItem(
                            'Mirrors & Windows',
                            _mirrorsWindows,
                            (val) => setState(() => _mirrorsWindows = val),
                          ),
                          _ChecklistItem(
                            'Signage (if applicable)',
                            _signage,
                            (val) => setState(() => _signage = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bodyDamageNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Body Damage Notes',
                          hintText: 'Describe any damage found...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        readOnly: widget.isViewOnly,
                      ),

                      const Divider(height: 32),

                      // Mechanical
                      _buildChecklistSection(
                        'Mechanical',
                        [
                          _ChecklistItem(
                            'Engine – oil & water',
                            _engineOilWater,
                            (val) => setState(() => _engineOilWater = val),
                          ),
                          _ChecklistItem(
                            'Brakes',
                            _brakes,
                            (val) => setState(() => _brakes = val),
                          ),
                          _ChecklistItem(
                            'Transmission',
                            _transmission,
                            (val) => setState(() => _transmission = val),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Electrical
                      _buildChecklistSection(
                        'Electrical',
                        [
                          _ChecklistItem(
                            'Both tail lights',
                            _tailLights,
                            (val) => setState(() => _tailLights = val),
                          ),
                          _ChecklistItem(
                            'Headlights (low beam)',
                            _headlightsLowBeam,
                            (val) => setState(() => _headlightsLowBeam = val),
                          ),
                          _ChecklistItem(
                            'Headlights (high beam)',
                            _headlightsHighBeam,
                            (val) => setState(() => _headlightsHighBeam = val),
                          ),
                          _ChecklistItem(
                            'Reverse lights',
                            _reverseLights,
                            (val) => setState(() => _reverseLights = val),
                          ),
                          _ChecklistItem(
                            'Brake lights',
                            _brakeLights,
                            (val) => setState(() => _brakeLights = val),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Cab
                      _buildChecklistSection(
                        'Cab',
                        [
                          _ChecklistItem(
                            'Windscreen & wipers',
                            _windscreenWipers,
                            (val) => setState(() => _windscreenWipers = val),
                          ),
                          _ChecklistItem(
                            'Horn',
                            _horn,
                            (val) => setState(() => _horn = val),
                          ),
                          _ChecklistItem(
                            'Indicators',
                            _indicators,
                            (val) => setState(() => _indicators = val),
                          ),
                          _ChecklistItem(
                            'Seat belts',
                            _seatBelts,
                            (val) => setState(() => _seatBelts = val),
                          ),
                          _ChecklistItem(
                            'Cleanliness',
                            _cabCleanliness,
                            (val) => setState(() => _cabCleanliness = val),
                          ),
                          _ChecklistItem(
                            'Service log book available',
                            _serviceLogBook,
                            (val) => setState(() => _serviceLogBook = val),
                          ),
                          _ChecklistItem(
                            'Spare keys available in store',
                            _spareKeys,
                            (val) => setState(() => _spareKeys = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section 3: Corrective Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. Corrective Actions/notes/issues',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _correctiveActionsController,
                        decoration: const InputDecoration(
                          hintText: 'Enter any corrective actions needed...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        readOnly: widget.isViewOnly,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section 4: Sign-off
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. Sign-off',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'I hereby declare that the above information is true and correct at the time of inspection.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _signatureController,
                        decoration: const InputDecoration(
                          labelText: 'Signature (Type your name) *',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: widget.isViewOnly,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Signature is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (!widget.isViewOnly) ...[
                ElevatedButton(
                  onPressed: _saveInspection,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.inspection != null
                        ? 'Update Inspection'
                        : 'Save Inspection',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistSection(
    String title,
    List<_ChecklistItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return CheckboxListTile(
            title: Text(item.label),
            value: item.value ?? false,
            onChanged: widget.isViewOnly
                ? null
                : (val) {
                    item.onChanged(val);
                  },
            tristate: false,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  void _saveInspection() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final vehicle = DatabaseService.getVehicle(_selectedVehicleId!);
    final store = DatabaseService.getStore(_selectedStoreId!);
    final driver = DatabaseService.getDriver(_selectedDriverId!);

    if (vehicle == null || store == null || driver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid vehicle, store, or driver')),
      );
      return;
    }

    final inspection = Inspection(
      id: widget.inspection?.id ?? const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      storeId: _selectedStoreId,
      driverId: _selectedDriverId,
      inspectionDate: _inspectionDate,
      odometerReading: _odometerController.text,
      vehicleRegistrationNo: vehicle.registrationNo,
      storeName: store.name,
      employeeName: driver.name,
      tyresTreadDepth: _tyresTreadDepth,
      wheelNuts: _wheelNuts,
      cleanliness: _cleanliness,
      bodyDamage: _bodyDamage,
      bodyDamageNotes: _bodyDamageNotesController.text.isNotEmpty
          ? _bodyDamageNotesController.text
          : null,
      mirrorsWindows: _mirrorsWindows,
      signage: _signage,
      engineOilWater: _engineOilWater,
      brakes: _brakes,
      transmission: _transmission,
      tailLights: _tailLights,
      headlightsLowBeam: _headlightsLowBeam,
      headlightsHighBeam: _headlightsHighBeam,
      reverseLights: _reverseLights,
      brakeLights: _brakeLights,
      windscreenWipers: _windscreenWipers,
      horn: _horn,
      indicators: _indicators,
      seatBelts: _seatBelts,
      cabCleanliness: _cabCleanliness,
      serviceLogBook: _serviceLogBook,
      spareKeys: _spareKeys,
      correctiveActions: _correctiveActionsController.text.isNotEmpty
          ? _correctiveActionsController.text
          : null,
      signature: _signatureController.text,
      createdAt: widget.inspection?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.inspection != null) {
      await DatabaseService.updateInspection(inspection);
    } else {
      await DatabaseService.addInspection(inspection);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.inspection != null
                ? 'Inspection updated successfully'
                : 'Inspection saved successfully',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _correctiveActionsController.dispose();
    _signatureController.dispose();
    _bodyDamageNotesController.dispose();
    super.dispose();
  }
}

class _ChecklistItem {
  final String label;
  final bool? value;
  final Function(bool?) onChanged;

  _ChecklistItem(this.label, this.value, this.onChanged);
}
