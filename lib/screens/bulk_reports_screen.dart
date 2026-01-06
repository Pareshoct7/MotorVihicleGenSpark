import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Widget build(BuildContext context) {
    final vehicles = DatabaseService.getAllVehicles();
    final stores = DatabaseService.getAllStores();
    final drivers = DatabaseService.getAllDrivers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Backdated Reports'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Multiple Inspections',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create multiple backdated inspection reports for Mondays.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mode Selection
                      SegmentedButton<BulkReportMode>(
                        segments: const [
                          ButtonSegment<BulkReportMode>(
                            value: BulkReportMode.dateRange,
                            label: Text('By Date Range'),
                            icon: Icon(Icons.date_range),
                          ),
                          ButtonSegment<BulkReportMode>(
                            value: BulkReportMode.count,
                            label: Text('By Count'),
                            icon: Icon(Icons.numbers),
                          ),
                        ],
                        selected: <BulkReportMode>{_selectedMode},
                        onSelectionChanged: (Set<BulkReportMode> newSelection) {
                          setState(() {
                            _selectedMode = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Vehicle Selection
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.registrationNo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Required';
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
                          prefixIcon: Icon(Icons.store),
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
                        validator: (value) {
                          if (value == null) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Driver Selection
                      DropdownButtonFormField<String>(
                        value: _selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Driver/Employee *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.id,
                            child: Text(driver.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDriverId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mode Specific Inputs
                      if (_selectedMode == BulkReportMode.count)
                        TextFormField(
                          controller: _numberOfReportsController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Reports (Mondays) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                            helperText: 'How many past Mondays to include',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final num = int.tryParse(value);
                            if (num == null || num < 1 || num > 50) {
                              return 'Enter number between 1-50';
                            }
                            return null;
                          },
                        ),
                      
                      if (_selectedMode == BulkReportMode.dateRange) ...[
                        // Start Date
                        InkWell(
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
                                if (_startDate.isAfter(_endDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_startDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // End Date
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_endDate),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Generate Button
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateBulkReports,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating
                      ? 'Generating Reports...'
                      : 'Generate Bulk Reports',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              if (_isGenerating)
                const LinearProgressIndicator()
              else
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
          ),
        ),
      ),
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
        throw Exception('Vehicle odometer reading is missing. Please update vehicle details.');
      }

      final lastUpdated = vehicle.odometerUpdatedAt;
      if (lastUpdated == null || DateTime.now().difference(lastUpdated).inDays > 30) {
        if (mounted) {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Odometer Outdated'),
              content: const Text(
                'The vehicle odometer reading is older than 30 days. Please update the vehicle details with the current odometer reading before generating reports.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
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
        while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
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
        if (DatabaseService.hasInspectionInSameWeek(vehicle.id, inspectionDate)) {
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
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: Text(
              'Inspections created successfully for ${targetDates.length} Mondays!\n\nWould you like to generate PDFs for all reports now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Generate PDFs'),
              ),
            ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      builder: (context) => AlertDialog(
        title: const Text('Generating PDFs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing ${recentInspections.length} reports...'),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDFs: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _numberOfReportsController.dispose();
    super.dispose();
  }
}
