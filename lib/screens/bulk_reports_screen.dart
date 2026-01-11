import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/usage_service.dart';
import '../services/preferences_service.dart';
import 'package:uuid/uuid.dart';
import '../models/inspection.dart';
import '../models/vehicle.dart';
import '../models/store.dart';
import '../models/driver.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'dart:math';

enum BulkReportMode { dateRange, count }

class BulkReportsScreen extends StatefulWidget {
  const BulkReportsScreen({super.key});

  @override
  State<BulkReportsScreen> createState() => _BulkReportsScreenState();
}

class _BulkReportsScreenState extends State<BulkReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberOfReportsController = TextEditingController(text: '5');

  BulkReportMode _selectedMode = BulkReportMode.dateRange;

  String? _selectedVehicleId;
  String? _selectedStoreId;
  String? _selectedDriverId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSmartDefaults();
  }

  Future<void> _loadSmartDefaults() async {
    final vehicleId = await PreferencesService.getDefaultVehicle();
    final storeId = await PreferencesService.getDefaultStore();
    final driverId = await PreferencesService.getDefaultDriver();

    if (mounted) {
      setState(() {
        _selectedVehicleId = vehicleId;
        _selectedStoreId = storeId;
        _selectedDriverId = driverId;
      });
    }

    if (vehicleId != null) {
      final bestStore = await UsageService.getMostFrequentStore(vehicleId);
      final bestDriver = await UsageService.getMostFrequentDriver(vehicleId);
      if (mounted) {
        setState(() {
          if (bestStore != null) _selectedStoreId = bestStore;
          if (bestDriver != null) _selectedDriverId = bestDriver;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              leading: Navigator.canPop(context) ? const BackButton() : null,
              expandedHeight: 140,
              floating: false,
              pinned: true,
              title: Text('BATCH GENERATOR'),
            ),
            SliverPadding(
              padding: EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt, color: Color(0xFFFFD700)),
                              SizedBox(width: 12),
                              Text(
                                'BATCH PARAMETERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Mode Selection
                          _buildPremiumSegmentedButton(),
                          const SizedBox(height: 32),

                          // Vehicle Selection
                          DropdownButtonFormField<String>(
                            initialValue: _selectedVehicleId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'TARGET VEHICLE',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            dropdownColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            items: vehicles
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text(
                                      v.registrationNo.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              setState(() => _selectedVehicleId = val);
                              if (val != null) {
                                final bestStore =
                                    await UsageService.getMostFrequentStore(
                                      val,
                                    );
                                final bestDriver =
                                    await UsageService.getMostFrequentDriver(
                                      val,
                                    );
                                if (mounted) {
                                  setState(() {
                                    if (bestStore != null)
                                      _selectedStoreId = bestStore;
                                    if (bestDriver != null)
                                      _selectedDriverId = bestDriver;
                                  });
                                }
                              }
                            },
                            validator: (val) => val == null ? 'REQUIRED' : null,
                          ),
                          const SizedBox(height: 16),

                          // Store Selection
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedStoreId,
                            decoration: InputDecoration(
                              labelText: 'BASE HUB',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            dropdownColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            items: stores
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              setState(() => _selectedStoreId = val);
                              if (val != null && _selectedVehicleId != null) {
                                await UsageService.trackSelection(
                                  _selectedVehicleId!,
                                  storeId: val,
                                );
                              }
                            },
                            validator: (val) => val == null ? 'REQUIRED' : null,
                          ),
                          const SizedBox(height: 16),

                          // Driver Selection
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedDriverId,
                            decoration: InputDecoration(
                              labelText: 'ASSIGNED DRIVER',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            dropdownColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            items: drivers
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(
                                      d.name.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              setState(() => _selectedDriverId = val);
                              if (val != null && _selectedVehicleId != null) {
                                await UsageService.trackSelection(
                                  _selectedVehicleId!,
                                  driverId: val,
                                );
                              }
                            },
                            validator: (val) => val == null ? 'REQUIRED' : null,
                          ),
                          const SizedBox(height: 16),

                          // Mode Specific Inputs
                          if (_selectedMode == BulkReportMode.count)
                            TextFormField(
                              controller: _numberOfReportsController,
                              decoration: InputDecoration(
                                labelText: 'BATCH COUNT (MONDAYS)',
                                prefixIcon: Icon(Icons.tag),
                                helperText: 'Enter 1-50 past Mondays',
                                helperStyle: TextStyle(color: Colors.white24),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'REQUIRED';
                                final num = int.tryParse(value);
                                if (num == null || num < 1 || num > 50)
                                  return 'MAX 50';
                                return null;
                              },
                            ),

                          if (_selectedMode == BulkReportMode.dateRange) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _startDate = date;
                                          if (_startDate.isAfter(_endDate))
                                            _endDate = _startDate;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'START DATE',
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_startDate),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate,
                                        firstDate: _startDate,
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null)
                                        setState(() => _endDate = date);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'END DATE',
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_endDate),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Generate Button
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateBulkReports,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFFFD700,
                            ), // Gold for Nitro
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.disabled))
                                return Colors.white10;
                              return const Color(0xFFFFD700);
                            }),
                          ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : FittedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'GENERATE BATCH',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),
                    if (!_isGenerating)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (_isGenerating) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'INJECTING DATA...',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD700),
                        ),
                        minHeight: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSegmentedButton() {
    return SegmentedButton<BulkReportMode>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedBackgroundColor: const Color(0xFF1F2937),
        selectedForegroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.white38,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      segments: const [
        ButtonSegment<BulkReportMode>(
          value: BulkReportMode.dateRange,
          label: Text(
            'RANGE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          icon: Icon(Icons.date_range_outlined, size: 16),
        ),
        ButtonSegment<BulkReportMode>(
          value: BulkReportMode.count,
          label: Text(
            'COUNT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          icon: Icon(Icons.tag_outlined, size: 16),
        ),
      ],
      selected: <BulkReportMode>{_selectedMode},
      onSelectionChanged: (val) => setState(() => _selectedMode = val.first),
    );
  }

  Future<void> _generateBulkReports() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final vehicle = DatabaseService.getVehicle(_selectedVehicleId!);
      final store = DatabaseService.getStore(_selectedStoreId!);
      final driver = DatabaseService.getDriver(_selectedDriverId!);

      if (vehicle == null || store == null || driver == null) {
        throw Exception('Invalid vehicle, store, or driver');
      }

      // Odometer Validation
      if (vehicle.odometerReading == null) {
        throw Exception(
          'Vehicle odometer reading is missing. Please update vehicle details.',
        );
      }

      final lastUpdated = vehicle.odometerUpdatedAt;
      if (lastUpdated == null ||
          DateTime.now().difference(lastUpdated).inDays > 30) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed, color: Color(0xFFFF5252), size: 48),
                    const SizedBox(height: 24),
                    Text(
                      'OUTDATED ODOMETER',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The vehicle odometer reading is older than 30 days. Please update the vehicle details with current telemetry before activating Nitro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text('ACKNOWLEDGE'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return; // Stop generation
      }

      final baseOdometer = vehicle.odometerReading!;

      // Calculate Target Dates (Mondays)
      List<DateTime> targetDates = [];

      if (_selectedMode == BulkReportMode.dateRange) {
        DateTime current = _startDate;
        while (current.isBefore(_endDate) ||
            current.isAtSameMomentAs(_endDate)) {
          if (current.weekday == DateTime.monday) {
            targetDates.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
      } else {
        // By Count
        final count = int.parse(_numberOfReportsController.text);
        DateTime current = DateTime.now();

        // Find most recent Monday (today or past)
        while (current.weekday != DateTime.monday) {
          current = current.subtract(const Duration(days: 1));
        }

        for (int i = 0; i < count; i++) {
          targetDates.add(current);
          current = current.subtract(const Duration(days: 7));
        }
      }

      if (targetDates.isEmpty) {
        throw Exception('No Mondays found in the selected range.');
      }

      // Sort Newest First for odometer calculation
      targetDates.sort((a, b) => b.compareTo(a));
      final numberOfReports = targetDates.length;
      final random = Random();

      // Calculate odometers (Newest to Oldest)
      // Newest (index 0) gets baseOdometer
      List<int> odometerReadings = List.filled(numberOfReports, 0);
      int currentReading = baseOdometer;

      for (int i = 0; i < numberOfReports; i++) {
        odometerReadings[i] = currentReading;

        // Subtract a random amount between 100-500km for the NEXT older report
        if (i < numberOfReports - 1) {
          final subtraction = 100 + random.nextInt(401); // 100 to 500
          currentReading -= subtraction;
        }
      }

      // Generate inspections (Iterate through prepared lists)
      // Note: Logic generates Newest First, effectively.
      for (int i = 0; i < numberOfReports; i++) {
        final inspectionDate = targetDates[i];
        final odometer = odometerReadings[i];

        // Check availability
        if (DatabaseService.hasInspectionInSameWeek(
          vehicle.id,
          inspectionDate,
        )) {
          // Skip duplicates instead of aborting whole batch?
          // Logic in previous version was to abort. Let's keep it safer for now, or just skip.
          // Given bulk nature, skipping duplicate weeks is often better UX than crashing.
          // Let's print a warning/log but skip.
          debugPrint('Skipping week of $inspectionDate as inspection exists.');
          continue;
        }

        final inspection = Inspection(
          id: const Uuid().v4(),
          vehicleId: vehicle.id,
          storeId: store.id,
          driverId: driver.id,
          inspectionDate: inspectionDate,
          odometerReading: odometer.toString(),
          vehicleRegistrationNo: vehicle.registrationNo,
          storeName: store.name,
          employeeName: driver.name,
          // All checkboxes set to true (passed inspection)
          tyresTreadDepth: true,
          wheelNuts: true,
          cleanliness: true,
          bodyDamage: true,
          mirrorsWindows: true,
          signage: true,
          engineOilWater: true,
          brakes: true,
          transmission: true,
          tailLights: true,
          headlightsLowBeam: true,
          headlightsHighBeam: true,
          reverseLights: true,
          brakeLights: true,
          windscreenWipers: true,
          horn: true,
          indicators: true,
          seatBelts: true,
          cabCleanliness: true,
          serviceLogBook: true,
          spareKeys: true,
          correctiveActions: 'Routine inspection - No issues found',
          signature: driver.name,
        );

        await DatabaseService.addInspection(inspection);
      }

      if (mounted) {
        // Ask if user wants to generate PDFs
        final generatePdfs = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF4FC3F7),
                    size: 48,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'BATCH COMPLETE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${targetDates.length} reports injected into the system. High-speed generation complete.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('LATER'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('EXPORT PDFs'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (generatePdfs == true && mounted) {
          // Pass the count of reports we just tried to generate
          await _generatePdfsForReports(targetDates.length);
        } else if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generatePdfsForReports(int count) async {
    // Get the latest inspections we just created
    final allInspections = DatabaseService.getAllInspections();
    final vehicle = DatabaseService.getVehicle(_selectedVehicleId!);

    if (vehicle == null) return;

    final recentInspections = allInspections
        .where((i) => i.vehicleId == vehicle.id)
        .take(count)
        .toList();

    // Show progress dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF4FC3F7)),
              const SizedBox(height: 24),
              Text(
                'EXPORTING TELEMETRY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing ${recentInspections.length} units...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Generate a single combined PDF for all reports
      await PdfService.shareClubbedInspections(recentInspections);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        Navigator.pop(context); // Close bulk reports screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recentInspections.length} PDFs generated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDFs: $e')));
      }
    }
  }

  @override
  void dispose() {
    _numberOfReportsController.dispose();
    super.dispose();
  }
}
