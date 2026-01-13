import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/reports_screen.dart';
import 'package:flutter_app/screens/vehicles_screen.dart';
import 'package:flutter_app/services/database_service.dart';
import 'package:flutter_app/models/store.dart';
import 'package:flutter_app/services/offline_drive_service.dart';
import 'package:intl/intl.dart';

// Simple model for a chat message
class AgentMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? actionWidget; // For buttons/cards

  AgentMessage({
    required this.text,
    required this.isUser,
    this.actionWidget,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now();
}

// Definition of an executable command
class AgentCommand {
  final String id;
  final List<String> keywords;
  final String description;
  final Future<AgentMessage> Function(String input, BuildContext context) execute;

  AgentCommand({
    required this.id,
    required this.keywords,
    required this.description,
    required this.execute,
  });
}

class AgentService {
  static final AgentService _instance = AgentService._internal();
  factory AgentService() => _instance;
  AgentService._internal();

  final List<AgentCommand> _commands = [];

  // Register core commands
  void init() {
    _commands.clear();
    
    // Navigation Commands
    _registerCommand(
      id: 'nav.home',
      keywords: ['home', 'dashboard', 'main screen'],
      description: 'Go to Home Screen',
      action: (input, context) async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return AgentMessage(text: 'Navigated to Home.', isUser: false);
      },
    );

     _registerCommand(
      id: 'nav.reports',
      keywords: ['report', 'reports', 'pdf', 'history'],
      description: 'Go to Reports Screen',
      action: (input, context) async {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (context) => const ReportsScreen()),
         );
         return AgentMessage(
           text: 'Here is the Reports screen.',
           isUser: false,
         );
      },
    );

    _registerCommand(
      id: 'nav.vehicles',
      keywords: ['vehicles', 'cars', 'trucks', 'garage', 'fleet'],
      description: 'Go to Garage',
      action: (input, context) async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehiclesScreen()),
        );
        return AgentMessage(text: 'Opened Garage.', isUser: false);
      },
    );

    
    // Hello / Help
    _registerCommand(
      id: 'system.hello',
      keywords: ['hello', 'hi', 'hey', 'start'],
      description: 'Greeting',
      action: (input, context) async {
        return AgentMessage(
          text: 'Hello! I am your enhanced offline assistant. I can help with finding vehicles, analyzing fleet health, or sharing offline records (e.g., "Share RHC34 as zip").',
          isUser: false,
        );
      },
    );
     _registerCommand(
      id: 'system.help',
      keywords: ['help', 'what can you do', 'features', 'assist'],
      description: 'List capabilities',
      action: (input, context) async {
        final commandList = _commands.map((c) => '- ${c.description}').join('\n');
        return AgentMessage(
          text: 'I can help with:\n$commandList\n\nTry asking: "Share RHC34 folder as zip for January 2026"',
          isUser: false,
        );
      },
    );

    // Report Generation Command (Smart)
    _registerCommand(
      id: 'report.generate',
      keywords: ['generate report', 'create pdf', 'download stats', 'make report', 'show report', 'get report'],
      description: 'Generate PDF Report (supports filters like "for Koutu last month")',
      action: (input, context) async {
        // 1. Extract Store
        final store = _extractStore(input);
        
        // 2. Extract Date Range
        final dateRange = _extractDateRange(input);

        // 3. Construct Message
        String responseText = 'Opening reports';
        if (store != null) responseText += ' for ${store.name}';
        if (dateRange != null) {
           final dateFormat = DateFormat('MMM d');
           responseText += ' from ${dateFormat.format(dateRange.start)} to ${dateFormat.format(dateRange.end)}';
        }
        responseText += '.';

        // 4. Navigate with Filters
        await Navigator.push(
           context, 
           MaterialPageRoute(
             builder: (_) => ReportsScreen(
               initialStoreId: store?.id,
               initialStartDate: dateRange?.start,
               initialEndDate: dateRange?.end,
             ),
           ),
        );

        return AgentMessage(
           text: responseText,
           isUser: false,
        );
      },
    );

    // Dynamic Vehicle Search Command
    _registerCommand(
      id: 'vehicle.search',
      keywords: ['find', 'search', 'lookup', 'where is', 'get vehicle'],
      description: 'Find a vehicle by Rego, Make, or Model',
      action: (input, context) async {
        final query = _cleanInput(input, ['find', 'search', 'lookup', 'where is', 'checked', 'vehicle', 'car', 'truck']);
        
        if (query.isEmpty) {
          return AgentMessage(text: 'What vehicle should I look for? Try "Find KUC487".', isUser: false);
        }

        final allVehicles = DatabaseService.getAllVehicles();
        final matches = allVehicles.where((v) {
          final q = query.toLowerCase();
          return v.registrationNo.toLowerCase().contains(q) ||
                 (v.make?.toLowerCase().contains(q) ?? false);
        }).toList();

        if (matches.isEmpty) {
           return AgentMessage(text: 'I couldn\'t find any vehicles matching "$query".', isUser: false);
        }

        return AgentMessage(
          text: 'Found ${matches.length} vehicle(s) matching "$query":',
          isUser: false,
          actionWidget: SizedBox(
            height: 120 * matches.length.clamp(1, 3).toDouble(),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final v = matches[index];
                return Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.white),
                    title: Text('${v.registrationNo} - ${v.make} ${v.model}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Exp: ${v.wofExpiryDate?.year ?? "-"}', style: const TextStyle(color: Colors.white70)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // ZIP & SHARE COMMAND (New Powerful Intent)
    _registerCommand(
      id: 'drive.share_zip',
      keywords: ['share zip', 'share folder', 'zip and share', 'send zip', 'share directory'],
      description: 'Share a vehicle folder as ZIP (e.g., "Share RHC34 folder as zip for Jan 2026")',
      action: (input, context) async {
        // 1. Extract Vehicle Reg
        final vehicleReg = _extractVehicleReg(input);
        if (vehicleReg == null) {
          return AgentMessage(text: 'Which vehicle folder do you want to share? Please mention the registration (e.g., RHC34).', isUser: false);
        }

        // 2. Extract Date (Month Year)
        final dateComponents = _extractMonthYear(input);
        final year = dateComponents?['year'] as int?;
        final month = dateComponents?['month'] as String?;

        final displayDate = (month != null && year != null) ? '$month $year' : 'current month';

        return AgentMessage(
          text: 'Searching for "$vehicleReg" folder for $displayDate...',
          isUser: false,
          actionWidget: FutureBuilder(
            future: OfflineDriveService.findVehicleFolder(vehicleReg, year: year, month: month),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
              }

              final dir = snapshot.data;
              if (dir == null) {
                return Text(
                  'Could not find a folder for $vehicleReg in $displayDate.\nTry ensuring spelling is correct or that reports exist for this date.',
                  style: TextStyle(color: Colors.orange),
                );
              }

              // Folder Found
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Found: ${dir.path.split('/').last}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4FC3F7)),
                    onPressed: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compressing & Sharing...')));
                        await OfflineDriveService.zipAndShareFolder(dir);
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }, 
                    icon: Icon(Icons.ios_share, color: Colors.black),
                    label: Text('ZIP & SHARE NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    // SYNC / GENERATE ALL COMMAND
    _registerCommand(
      id: 'drive.sync',
      keywords: ['sync drive', 'generate all', 'update offline drive', 'refresh reports', 'backfill'],
      description: 'Sync Offline Drive (Generate missing reports for all vehicles)',
      action: (input, context) async {
        return AgentMessage(
          text: 'Starting Offline Drive Sync...',
          isUser: false,
          actionWidget: FutureBuilder(
            future: OfflineDriveService.generateAllBackfill(
              onProgress: (c, t, s) {},
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Generating Reports...', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    LinearProgressIndicator(color: Color(0xFF4FC3F7)),
                  ],
                );
              }
              if (snapshot.hasError) {
                return Text('Sync Failed: ${snapshot.error}', style: TextStyle(color: Colors.red));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Sync Complete!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   Text('All missing reports have been generated and signed.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                   SizedBox(height: 8),
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1C222D)),
                     onPressed: () {
                        // Navigate to Offline Drive folder
                        // We can't easily nav to specific folder without context, but we can open the screen
                        // For now just show "Done"
                     }, 
                     child: Text('Drive Updated'),
                   )
                ],
              );
            },
          ),
        );
      },
    );

    // CLEAR DRIVE COMMAND
    _registerCommand(
      id: 'drive.clear',
      keywords: ['clear drive', 'delete all reports', 'wipe offline data', 'reset drive'],
      description: 'Clear all offline data (Requires confirmation)',
      action: (input, context) async {
        return AgentMessage(
          text: 'Are you sure you want to delete ALL offline reports? This cannot be undone.',
          isUser: false,
          actionWidget: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF5252)),
                  onPressed: () async {
                    await OfflineDriveService.clearOfflineDrive();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Drive Cleared')));
                  }, 
                  child: Text('YES, CLEAR ALL', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {}, 
                  child: Text('CANCEL'),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Fleet Status Command
    _registerCommand(
      id: 'stats.status',
      keywords: ['status', 'overview', 'attention', 'problems', 'expired', 'health'],
      description: 'Check fleet health',
      action: (input, context) async {
        final needingAttention = DatabaseService.getVehiclesNeedingAttention();
        
        if (needingAttention.isEmpty) {
          return AgentMessage(text: 'Good news! All vehicles are healthy. No immediate attention needed.', isUser: false);
        }

        return AgentMessage(
          text: 'Warning: ${needingAttention.length} vehicle(s) need attention!',
          isUser: false,
          actionWidget: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()));
            },
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            label: const Text('View Issues in Garage', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _registerCommand({
    required String id,
    required List<String> keywords,
    required String description,
    required Future<AgentMessage> Function(String input, BuildContext context) action,
  }) {
    _commands.add(AgentCommand(
      id: id,
      keywords: keywords,
      description: description,
      execute: action,
    ));
  }

  // CORE NLP ENGINE (Zero-Cost / Offline)
  Future<AgentMessage> processQuery(String input, BuildContext context) async {
    final lowerInput = input.toLowerCase().trim();
    
    // 1. Fuzzy Match using Levenshtein (Weighted Ratio)
    AgentCommand? bestMatch;
    int bestScore = 0;

    for (var cmd in _commands) {
      for (var keyword in cmd.keywords) {
        final score = weightedRatio(lowerInput, keyword);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = cmd;
        }
      }
    }

    // 2. Direct Logic Overrides for complex sentences
    if (lowerInput.contains('zip') && lowerInput.contains('share')) {
      bestMatch = _commands.firstWhere((c) => c.id == 'drive.share_zip');
      bestScore = 100;
    }

    // Threshold for acceptance
    if (bestMatch != null && bestScore > 60) {
      debugPrint('Agent matched "${bestMatch.id}" with score $bestScore');
      return await bestMatch.execute(input, context);
    }

    // 3. Fallback
    return AgentMessage(
      text: "I didn't understand that. Try asking for 'help' to see what I can do.",
      isUser: false,
    );
  }

  // --- Entity Extraction Helpers ---

  String _cleanInput(String input, List<String> removeWords) {
    String result = input.toLowerCase();
    for (var word in removeWords) {
      result = result.replaceAll(word, '');
    }
    return result.trim();
  }

  String? _extractVehicleReg(String input) {
    // Look for patterns like RHC34, KUC487 (3-6 chars, mixed numbers/letters often)
    // Heuristic: Split by space, look for short uppercase words that are NOT months or keywords
    final parts = input.split(' ');
    final ignore = ['share', 'zip', 'folder', 'directory', 'as', 'for', 'in', 'of', 'vehicle', 'car'];
    
    for (var part in parts) {
      final clean = part.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (clean.length >= 3 && clean.length <= 6 && !ignore.contains(clean.toLowerCase())) {
        // Check if it's a month
        if (_isMonth(clean)) continue;
        return clean;
      }
    }
    return null;
  }

  bool _isMonth(String s) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC', 'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return months.contains(s);
  }

  Map<String, dynamic>? _extractMonthYear(String input) {
    // Match "January 2026", "Jan 2026", "10/2025"
    final yearRegex = RegExp(r'(20\d{2})');
    final matchYear = yearRegex.firstMatch(input);
    int? year;
    if (matchYear != null) {
      year = int.tryParse(matchYear.group(1)!);
    }

    String? month;
    final monthsMap = {
      'jan': 'January', 'january': 'January',
      'feb': 'February', 'february': 'February',
      'mar': 'March', 'march': 'March',
      'apr': 'April', 'april': 'April',
      'may': 'May',
      'jun': 'June', 'june': 'June',
      'jul': 'July', 'july': 'July',
      'aug': 'August', 'august': 'August',
      'sep': 'September', 'september': 'September',
      'oct': 'October', 'october': 'October',
      'nov': 'November', 'november': 'November',
      'dec': 'December', 'december': 'December'
    };

    final lower = input.toLowerCase();
    for (var key in monthsMap.keys) {
      if (lower.contains(key)) {
        month = monthsMap[key];
        break;
      }
    }

    if (month == null && year == null) return null;
    return {'month': month, 'year': year};
  }

  Store? _extractStore(String input) {
    final stores = DatabaseService.getAllStores();
    final lowerInput = input.toLowerCase();

    // 1. Exact Name Match
    for (var store in stores) {
      if (lowerInput.contains(store.name.toLowerCase())) {
        return store;
      }
    }

    // 2. Fuzzy / Keyword Match
    Store? bestMatch;
    int bestLen = 0;

    for (var store in stores) {
      final parts = store.name.toLowerCase().split(' ');
      
      for (var part in parts) {
        if (part.length < 3) continue; 
        if (lowerInput.contains(part)) {
           if (part.length > bestLen) {
             bestLen = part.length;
             bestMatch = store;
           }
        }
      }
    }
    return bestMatch;
  }

  DateTimeRange? _extractDateRange(String input) {
    final lowerInput = input.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lowerInput.contains('today')) {
      return DateTimeRange(start: today, end: today);
    }
    
    if (lowerInput.contains('yesterday')) {
      final yesterday = today.subtract(const Duration(days: 1));
      return DateTimeRange(start: yesterday, end: yesterday);
    }

    if (lowerInput.contains('this week')) {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: startOfWeek, end: today);
    }
    
    if (lowerInput.contains('last week')) {
      final startOfLastWeek = today.subtract(Duration(days: today.weekday - 1 + 7));
      final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
      return DateTimeRange(start: startOfLastWeek, end: endOfLastWeek);
    }

    if (lowerInput.contains('this month')) {
      final startOfMonth = DateTime(today.year, today.month, 1);
      return DateTimeRange(start: startOfMonth, end: today);
    }

    if (lowerInput.contains('last month')) {
      final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
      final endOfLastMonth = DateTime(today.year, today.month, 0); 
      return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
    }

    return null; 
  }
}
