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

class _InspectionFormScreenState extends State<InspectionFormScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late List<Animation<double>> _staggeredAnimations;
  
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
    _initAnimations();
    if (widget.inspection != null) {
      _loadInspectionData();
    } else if (widget.baseInspection != null) {
      _loadBaseInspectionData();
    } else {
      _loadDefaults();
    }
  }

  void _initAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _staggeredAnimations = List.generate(
      10,
      (index) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          0.1 + (index * 0.05),
          0.6 + (index * 0.05),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _entranceController.forward();
  }

  double get _completionPercentage {
    final fields = [
      _tyresTreadDepth, _wheelNuts, _cleanliness, _bodyDamage, _mirrorsWindows,
      _signage, _engineOilWater, _brakes, _transmission, _tailLights,
      _headlightsLowBeam, _headlightsHighBeam, _reverseLights, _brakeLights,
      _windscreenWipers, _horn, _indicators, _seatBelts, _cabCleanliness,
      _serviceLogBook, _spareKeys
    ];
    final total = fields.length;
    final completed = fields.where((f) => f != null).length;
    return (completed / total) * 100;
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
    final accentColor = const Color(0xFF4FC3F7);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              leading: Navigator.canPop(context) ? const BackButton() : null,
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0D1117),
              title: const Text('INSPECTION'),
              actions: [
                if (widget.inspection != null)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 28),
                    onPressed: () => PdfService.shareTemplateMatchingInspection(widget.inspection!),
                  ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                             'SYSTEM READINESS',
                             style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white24),
                          ),
                          Text(
                            '${_completionPercentage.toInt()}%',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _completionPercentage / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Section 1: Telemetry
                  _buildAnimatedSection(0, 'TELEMETRY', [
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(labelText: 'TARGET VEHICLE', prefixIcon: Icon(Icons.directions_car_outlined)),
                      dropdownColor: const Color(0xFF161B22),
                      items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.registrationNo))).toList(),
                      onChanged: widget.isViewOnly ? null : (val) => setState(() => _selectedVehicleId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStoreId,
                      decoration: const InputDecoration(labelText: 'STAGING HUB', prefixIcon: Icon(Icons.store_outlined)),
                      dropdownColor: const Color(0xFF161B22),
                      items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.toUpperCase()))).toList(),
                      onChanged: widget.isViewOnly ? null : (val) => setState(() => _selectedStoreId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            decoration: const InputDecoration(labelText: 'ODOMETER', prefixIcon: Icon(Icons.speed_outlined)),
                            keyboardType: TextInputType.number,
                            readOnly: widget.isViewOnly,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: widget.isViewOnly ? null : () async {
                              final date = await showDatePicker(context: context, initialDate: _inspectionDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setState(() => _inspectionDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'SCAN DATE'),
                              child: Text(DateFormat('dd / MM / yyyy').format(_inspectionDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDriverId,
                      decoration: const InputDecoration(labelText: 'OPERATOR', prefixIcon: Icon(Icons.person_outline)),
                      dropdownColor: const Color(0xFF161B22),
                      items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name.toUpperCase()))).toList(),
                      onChanged: widget.isViewOnly ? null : (val) => setState(() => _selectedDriverId = val),
                    ),
                  ]),

                  // Section 2: Diagnostics (Checklist)
                  _buildAnimatedSection(1, 'SYSTEM DIAGNOSTICS', [
                    _buildThematicCheckGroup('TIRES & WHEELS', [
                      _ChecklistItem('TREAD DEPTH SCAN', _tyresTreadDepth, (v) => setState(() => _tyresTreadDepth = v)),
                      _ChecklistItem('WHEEL NUT TORQUE', _wheelNuts, (v) => setState(() => _wheelNuts = v)),
                    ]),
                    _buildThematicCheckGroup('CHASSIS & EXTERIOR', [
                      _ChecklistItem('BODY CLEANLINESS', _cleanliness, (v) => setState(() => _cleanliness = v)),
                      _ChecklistItem('SURFACE INTEGRITY (NO DAMAGE)', _bodyDamage, (v) => setState(() => _bodyDamage = v)),
                      _ChecklistItem('OPTICS (MIRRORS & WINDOWS)', _mirrorsWindows, (v) => setState(() => _mirrorsWindows = v)),
                      _ChecklistItem('LIVERY / SIGNAGE', _signage, (v) => setState(() => _signage = v)),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextFormField(
                        controller: _bodyDamageNotesController,
                        decoration: const InputDecoration(labelText: 'BODY DAMAGE LOG', hintText: 'LOG ANOMALIES...'),
                        maxLines: 2,
                        readOnly: widget.isViewOnly,
                      ),
                    ),
                    _buildThematicCheckGroup('ENGINE & DRIVETRAIN', [
                      _ChecklistItem('FLUID LEVELS (OIL/WATER)', _engineOilWater, (v) => setState(() => _engineOilWater = v)),
                      _ChecklistItem('BRAKE CALIBRATION', _brakes, (v) => setState(() => _brakes = v)),
                      _ChecklistItem('TRANSMISSION RESPONSE', _transmission, (v) => setState(() => _transmission = v)),
                    ]),
                    _buildThematicCheckGroup('ILLUMINATION', [
                      _ChecklistItem('TAIL LIGHT ARRAYS', _tailLights, (v) => setState(() => _tailLights = v)),
                      _ChecklistItem('HEADLIGHT LOW BEAM', _headlightsLowBeam, (v) => setState(() => _headlightsLowBeam = v)),
                      _ChecklistItem('HEADLIGHT HIGH BEAM', _headlightsHighBeam, (v) => setState(() => _headlightsHighBeam = v)),
                      _ChecklistItem('REVERSE THRUST LIGHTS', _reverseLights, (v) => setState(() => _reverseLights = v)),
                      _ChecklistItem('BRAKE LIGHT RESPONSE', _brakeLights, (v) => setState(() => _brakeLights = v)),
                    ]),
                    _buildThematicCheckGroup('CAB & INTERIOR', [
                      _ChecklistItem('WINDSCREEN & WIPERS', _windscreenWipers, (v) => setState(() => _windscreenWipers = v)),
                      _ChecklistItem('ACOUSTIC HORN', _horn, (v) => setState(() => _horn = v)),
                      _ChecklistItem('DIRECTIONAL INDICATORS', _indicators, (v) => setState(() => _indicators = v)),
                      _ChecklistItem('SAFETY RESTRAINTS (BELTS)', _seatBelts, (v) => setState(() => _seatBelts = v)),
                      _ChecklistItem('COCKPIT CLEANLINESS', _cabCleanliness, (v) => setState(() => _cabCleanliness = v)),
                      _ChecklistItem('SERVICE LOGS ONBOARD', _serviceLogBook, (v) => setState(() => _serviceLogBook = v)),
                      _ChecklistItem('AUXILIARY KEYS IN STORE', _spareKeys, (v) => setState(() => _spareKeys = v)),
                    ]),
                  ]),

                  // Section 3: Corrective Actions
                  _buildAnimatedSection(2, 'CORRECTIVE ACTIONS', [
                    TextFormField(
                      controller: _correctiveActionsController,
                      decoration: const InputDecoration(labelText: 'REACTION LOG', hintText: 'LOG CORRECTIVE MEASURES...'),
                      maxLines: 4,
                      readOnly: widget.isViewOnly,
                    ),
                  ]),

                  // Section 4: Sign-off
                  _buildAnimatedSection(3, 'SYSTEM AUTHENTICATION', [
                    const Text(
                      'I CONFIRM ALL PERFORMANCE DATA IS ACCURATE.',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _signatureController,
                      decoration: const InputDecoration(labelText: 'DIGITAL SIGNATURE', prefixIcon: Icon(Icons.history_edu_outlined)),
                      readOnly: widget.isViewOnly,
                      validator: (val) => (val == null || val.isEmpty) ? 'REQUIRED' : null,
                    ),
                  ]),

                  const SizedBox(height: 40),

                  if (!widget.isViewOnly) ...[
                    ElevatedButton(
                      onPressed: _saveInspection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined),
                          const SizedBox(width: 12),
                          Text(
                            widget.inspection != null ? 'UPDATE INSPECTION' : 'SAVE INSPECTION',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(int index, String title, List<Widget> children) {
    final animation = _staggeredAnimations[index];
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThematicCheckGroup(String title, List<_ChecklistItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4FC3F7), letterSpacing: 1),
          ),
        ),
        ...items.map((item) {
          final isChecked = item.value ?? false;
          return InkWell(
            onTap: widget.isViewOnly ? null : () => item.onChanged(!isChecked),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                   Container(
                     width: 20,
                     height: 20,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(6),
                       border: Border.all(
                         color: isChecked ? const Color(0xFF4ADE80) : Colors.white10,
                         width: 2,
                       ),
                       color: isChecked ? const Color(0xFF4ADE80).withValues(alpha: 0.1) : Colors.transparent,
                     ),
                     child: isChecked ? const Icon(Icons.check, size: 14, color: Color(0xFF4ADE80)) : null,
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                        item.label,
                        style: TextStyle(
                          color: isChecked ? Colors.white : Colors.white38,
                          fontSize: 12,
                          fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                          letterSpacing: 0.5,
                        ),
                     ),
                   ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
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

    // Check for existing inspection in the same week (only for new inspections)
    if (widget.inspection == null) {
      final hasExisting =
          DatabaseService.hasInspectionInSameWeek(_selectedVehicleId!, _inspectionDate);
      if (hasExisting) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF0D1117),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 48),
                  const SizedBox(height: 24),
                  const Text(
                    'DUPLICATE ENTRY',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'An inspection already exists for this vehicle in the selected week. System protocols only allow one entry per week.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
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
                ? 'TELEMETRY UPDATED'
                : 'TELEMETRY COMMITTED',
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
    _entranceController.dispose();
    super.dispose();
  }
}

class _ChecklistItem {
  final String label;
  final bool? value;
  final Function(bool?) onChanged;

  _ChecklistItem(this.label, this.value, this.onChanged);
}
