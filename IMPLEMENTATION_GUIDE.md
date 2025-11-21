# Implementation Guide for Remaining Features

This guide provides step-by-step instructions for implementing the remaining requested features.

---

## 📋 Feature Status

### ✅ Completed (Committed to GitHub)
1. ✅ Word template updated with exact user template
2. ✅ Python Word/PDF generator fixed with precise mapping
3. ✅ Store Number field added to Store model
4. ✅ Hive adapters regenerated

### 🔄 In Progress / Pending
1. ⏳ Integrate Store Number throughout app (30+ files)
2. ⏳ Implement Dark/Light/System theme support
3. ⏳ Add AI auto-complete features
4. ⏳ Implement behavior learning system
5. ⏳ UI/UX redesign with modern components

---

## 1. 🏪 Store Number Integration

### **Objective:** Show store number in brackets next to store name everywhere in the app

### **Files to Update:**

#### **A. Stores Screen** (`lib/screens/stores_screen.dart`)
Update the form to add Store Number input field:

```dart
// Add after the name field
TextFormField(
  controller: _storeNumberController,
  decoration: const InputDecoration(
    labelText: 'Store Number',
    hintText: 'e.g., ST001, STORE-123',
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    // Optional field, no validation needed
    return null;
  },
),
```

#### **B. Update All Dropdowns**
Find all `DropdownButtonFormField<String>` widgets that show stores and update:

**Before:**
```dart
DropdownMenuItem(
  value: store.id,
  child: Text(store.name),
),
```

**After:**
```dart
DropdownMenuItem(
  value: store.id,
  child: Text(store.displayName), // Uses 'Name (Number)' format
),
```

**Files with store dropdowns:**
- `lib/screens/inspection_form_screen.dart`
- `lib/screens/bulk_reports_screen.dart`
- `lib/screens/reports_screen.dart`
- `lib/screens/settings_screen.dart`

#### **C. Update Display Widgets**
Find all places showing `store.name` and replace with `store.displayName`:

```dart
// Search pattern: store.name or inspection.storeName
// Replace with: store.displayName or inspection.storeDisplayName
```

**Files to check:**
- `lib/screens/home_screen.dart`
- `lib/screens/inspection_history_screen.dart`
- `lib/screens/inspection_form_screen.dart`

#### **D. Update Inspection Model**
Add storeNumber to inspection:

```dart
@HiveField(X) // Use next available field number
String? storeNumber;

// Add to constructor and JSON methods
```

#### **E. Update Word/PDF Service**
Already done! The `word_pdf_generator.py` now checks for storeNumber.

---

## 2. 🎨 Dark/Light/System Theme Implementation

### **Step 1: Add Theme Provider**

Create `lib/providers/theme_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);
    
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }
}
```

### **Step 2: Define Light and Dark Themes**

Create `lib/config/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
```

### **Step 3: Update main.dart**

```dart
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Motor Vehicle Inspection',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
```

### **Step 4: Add Theme Selector in Settings**

Update `lib/screens/settings_screen.dart`:

```dart
Card(
  child: Column(
    children: [
      const ListTile(
        leading: Icon(Icons.palette),
        title: Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      RadioListTile<ThemeMode>(
        title: const Text('System Default'),
        value: ThemeMode.system,
        groupValue: Provider.of<ThemeProvider>(context).themeMode,
        onChanged: (mode) {
          if (mode != null) {
            Provider.of<ThemeProvider>(context, listen: false).setThemeMode(mode);
          }
        },
      ),
      RadioListTile<ThemeMode>(
        title: const Text('Light'),
        value: ThemeMode.light,
        groupValue: Provider.of<ThemeProvider>(context).themeMode,
        onChanged: (mode) {
          if (mode != null) {
            Provider.of<ThemeProvider>(context, listen: false).setThemeMode(mode);
          }
        },
      ),
      RadioListTile<ThemeMode>(
        title: const Text('Dark'),
        value: ThemeMode.dark,
        groupValue: Provider.of<ThemeProvider>(context).themeMode,
        onChanged: (mode) {
          if (mode != null) {
            Provider.of<ThemeProvider>(context, listen: false).setThemeMode(mode);
          }
        },
      ),
    ],
  ),
),
```

---

## 3. 🤖 AI Auto-Complete Feature

### **Objective:** Learn from user inputs and provide smart suggestions

### **Step 1: Create AI Learning Service**

Create `lib/services/ai_learning_service.dart`:

```dart
import 'package:hive/hive.dart';

class AILearningService {
  static const String _boxName = 'ai_learning';
  static late Box<Map<dynamic, dynamic>> _learningBox;
  
  static Future<void> init() async {
    _learningBox = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }
  
  /// Record user input for a specific field
  static Future<void> recordInput(String fieldName, String value) async {
    if (value.isEmpty) return;
    
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <dynamic, dynamic>{});
    
    // Count frequency of this input
    final count = (data?[value] ?? 0) as int;
    data?[value] = count + 1;
    
    await _learningBox.put(key, data!);
  }
  
  /// Get suggestions for a field based on input prefix
  static List<String> getSuggestions(String fieldName, String prefix) {
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <dynamic, dynamic>{});
    
    if (data == null || data.isEmpty) return [];
    
    // Filter by prefix and sort by frequency
    final suggestions = data.entries
        .where((entry) {
          final text = entry.key.toString().toLowerCase();
          final searchText = prefix.toLowerCase();
          return text.contains(searchText);
        })
        .toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return suggestions
        .map((entry) => entry.key.toString())
        .take(5)
        .toList();
  }
  
  /// Get most frequently used values for a field
  static List<String> getTopValues(String fieldName, {int limit = 3}) {
    final key = 'field_$fieldName';
    final data = _learningBox.get(key, defaultValue: <dynamic, dynamic>{});
    
    if (data == null || data.isEmpty) return [];
    
    final sorted = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return sorted
        .map((entry) => entry.key.toString())
        .take(limit)
        .toList();
  }
  
  /// Clear all learning data
  static Future<void> clearAllData() async {
    await _learningBox.clear();
  }
}
```

### **Step 2: Create Smart TextFormField Widget**

Create `lib/widgets/smart_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/ai_learning_service.dart';

class SmartTextField extends StatefulWidget {
  final String fieldName;
  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enableSuggestions;
  
  const SmartTextField({
    super.key,
    required this.fieldName,
    required this.labelText,
    required this.controller,
    this.validator,
    this.enableSuggestions = true,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  void _onTextChanged() {
    if (!widget.enableSuggestions) return;
    
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() {
        _suggestions = AILearningService.getTopValues(widget.fieldName);
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = AILearningService.getSuggestions(widget.fieldName, text);
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
    }
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _onTextChanged();
    } else {
      setState(() => _showSuggestions = false);
      // Record input when field loses focus
      if (widget.controller.text.isNotEmpty) {
        AILearningService.recordInput(widget.fieldName, widget.controller.text);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: widget.enableSuggestions
                ? const Icon(Icons.auto_awesome, size: 16)
                : null,
          ),
          validator: widget.validator,
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            elevation: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((suggestion) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 16),
                  title: Text(suggestion),
                  onTap: () {
                    widget.controller.text = suggestion;
                    _focusNode.unfocus();
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }
}
```

### **Step 3: Initialize AI Service**

Update `lib/services/database_service.dart`:

```dart
static Future<void> init() async {
  await Hive.initFlutter();
  
  // Register adapters
  // ... existing code ...
  
  // Initialize AI Learning Service
  await AILearningService.init();
}
```

### **Step 4: Use Smart TextFields**

Replace regular TextFormFields in `inspection_form_screen.dart`:

```dart
// Replace Vehicle Registration field
SmartTextField(
  fieldName: 'vehicle_registration',
  labelText: 'Vehicle Registration No',
  controller: _vehicleRegController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter vehicle registration';
    }
    return null;
  },
),

// Replace Odometer field
SmartTextField(
  fieldName: 'odometer_reading',
  labelText: 'Odometer Reading',
  controller: _odometerController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter odometer reading';
    }
    return null;
  },
),
```

---

## 4. 🔮 Predictive Maintenance Alerts

### **Objective:** Smart suggestions based on inspection history

### **Step 1: Create Prediction Service**

Create `lib/services/prediction_service.dart`:

```dart
import '../models/inspection.dart';
import '../models/vehicle.dart';
import 'database_service.dart';

class PredictionService {
  /// Predict next service based on inspection history
  static Future<Map<String, dynamic>> predictNextService(String vehicleId) async {
    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
    
    if (inspections.length < 2) {
      return {
        'canPredict': false,
        'message': 'Need more inspection history',
      };
    }
    
    // Calculate average interval between inspections
    int totalDays = 0;
    for (int i = 0; i < inspections.length - 1; i++) {
      final days = inspections[i].inspectionDate
          .difference(inspections[i + 1].inspectionDate)
          .inDays;
      totalDays += days;
    }
    
    final avgInterval = totalDays / (inspections.length - 1);
    final lastInspection = inspections.first;
    final predictedDate = lastInspection.inspectionDate.add(
      Duration(days: avgInterval.round()),
    );
    
    return {
      'canPredict': true,
      'predictedDate': predictedDate,
      'avgIntervalDays': avgInterval.round(),
      'confidence': inspections.length >= 5 ? 'high' : 'medium',
    };
  }
  
  /// Identify recurring issues
  static Future<List<String>> identifyRecurringIssues(String vehicleId) async {
    final inspections = DatabaseService.getAllInspections()
        .where((i) => i.vehicleId == vehicleId)
        .toList();
    
    if (inspections.length < 3) return [];
    
    final issues = <String>[];
    
    // Check for patterns in failed items
    final failedItems = <String, int>{};
    
    for (final inspection in inspections) {
      if (inspection.tyresTreadDepth == false) {
        failedItems['Tyres (tread depth)'] = (failedItems['Tyres (tread depth)'] ?? 0) + 1;
      }
      if (inspection.brakes == false) {
        failedItems['Brakes'] = (failedItems['Brakes'] ?? 0) + 1;
      }
      // Add more checks...
    }
    
    // Items that failed in 40% or more inspections
    final threshold = inspections.length * 0.4;
    for (final entry in failedItems.entries) {
      if (entry.value >= threshold) {
        issues.add('${entry.key} - Failed ${entry.value}/${inspections.length} times');
      }
    }
    
    return issues;
  }
}
```

### **Step 2: Add Prediction Widget to Home Screen**

Update `lib/screens/home_screen.dart`:

```dart
// Add after quick stats
FutureBuilder<List<Widget>>(
  future: _buildPredictionCards(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '🔮 Smart Predictions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...snapshot.data!,
        ],
      );
    }
    return const SizedBox.shrink();
  },
),

// Add method
Future<List<Widget>> _buildPredictionCards() async {
  final vehicles = DatabaseService.getAllVehicles();
  final predictions = <Widget>[];
  
  for (final vehicle in vehicles.take(3)) {
    final prediction = await PredictionService.predictNextService(vehicle.id);
    
    if (prediction['canPredict'] == true) {
      predictions.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: Text('${vehicle.registrationNo} - Next Service'),
            subtitle: Text(
              'Predicted: ${DateFormat('dd MMM yyyy').format(prediction['predictedDate'])}',
            ),
            trailing: Text(
              '${prediction['avgIntervalDays']} days',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
  }
  
  return predictions;
}
```

---

## 5. 🎨 UI/UX Improvements

### **Modern Card Design**

Replace basic cards with elevated cards:

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    onTap: () { /* action */ },
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: /* content */,
    ),
  ),
)
```

### **Add Animations**

```dart
import 'package:flutter/material.dart';

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  
  const SlideInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });
  
  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
```

---

## 📊 Testing & Validation

### Test Checklist:

#### Store Number Feature:
- [ ] Create store with number
- [ ] Verify display in dropdowns
- [ ] Check PDF generation
- [ ] Test Word document output

#### Theme Feature:
- [ ] Switch to Light theme
- [ ] Switch to Dark theme
- [ ] Set to System default
- [ ] Verify persistence after app restart

#### AI Features:
- [ ] Enter data multiple times
- [ ] Verify suggestions appear
- [ ] Test frequency ranking
- [ ] Check prediction accuracy

---

## 🚀 Deployment Steps

1. **Run build_runner** (if models changed):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Test locally**:
   ```bash
   flutter run -d web-server --web-port 5060
   ```

3. **Build for production**:
   ```bash
   flutter build web --release
   flutter build apk --release
   ```

4. **Commit changes**:
   ```bash
   git add .
   git commit -m "feat: Implement themes and AI features"
   git push origin main
   ```

---

## 📚 Additional Resources

- [Flutter Theming Guide](https://docs.flutter.dev/cookbook/design/themes)
- [Provider Package](https://pub.dev/packages/provider)
- [Hive Database](https://docs.hivedb.dev/)
- [Material Design 3](https://m3.material.io/)

---

**Last Updated**: November 2024  
**Version**: 2.0.0  
**Status**: Implementation Guide
