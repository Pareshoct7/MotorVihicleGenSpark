import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/reports_screen.dart';
import 'package:flutter_app/screens/vehicles_screen.dart';
import 'package:flutter_app/services/database_service.dart';
import 'package:flutter_app/models/store.dart';
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
          text: 'Hello! I am your offline assistant. You can ask me to navigate pages or explain features.',
          isUser: false,
        );
      },
    );
     _registerCommand(
      id: 'system.help',
      keywords: ['help', 'what can you do', 'features'],
      description: 'List capabilities',
      action: (input, context) async {
        final commandList = _commands.map((c) => '- ${c.description}').join('\n');
        return AgentMessage(
          text: 'I can help with:\n$commandList',
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
        // Simple entity extraction (remove "find", "search", etc.)
        final query = input.replaceAll(RegExp(r'find|search|lookup|where is|checked|vehicle|car|truck', caseSensitive: false), '').trim();
        
        if (query.isEmpty) {
          return AgentMessage(text: 'What vehicle should I look for? Try "Find KUC487" or "Search Nissan".', isUser: false);
        }

        final allVehicles = DatabaseService.getAllVehicles();
        final matches = allVehicles.where((v) {
          final q = query.toLowerCase();
          return v.registrationNo.toLowerCase().contains(q) ||
                 (v.make?.toLowerCase().contains(q) ?? false) ||
                 (v.model?.toLowerCase().contains(q) ?? false);
        }).toList();

        if (matches.isEmpty) {
           return AgentMessage(text: 'I couldn\'t find any vehicles matching "$query".', isUser: false);
        }

        return AgentMessage(
          text: 'Found ${matches.length} vehicle(s) matching "$query":',
          isUser: false,
          actionWidget: SizedBox(
            height: 120 * matches.length.clamp(1, 3).toDouble(), // Limit height
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final v = matches[ index];
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
        // Calculate similarity score (0-100)
        final score = weightedRatio(lowerInput, keyword);
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = cmd;
        }
      }
    }

    // Threshold for acceptance (e.g., 60% similarity)
    if (bestMatch != null && bestScore > 60) {
      debugPrint('Agent matched "${bestMatch.id}" with score $bestScore');
      return await bestMatch.execute(input, context);
    }

    // 2. Fallback
    return AgentMessage(
      text: "I didn't understand that. Try asking for 'help' to see what I can do.",
      isUser: false,
    );
  }

  // --- Entity Extraction Helpers ---

  Store? _extractStore(String input) {
    final stores = DatabaseService.getAllStores();
    final lowerInput = input.toLowerCase();

    // 1. Exact Name Match
    for (var store in stores) {
      if (lowerInput.contains(store.name.toLowerCase())) {
        return store;
      }
    }

    // 2. Fuzzy / Keyword Match (e.g. "Koutu" in "Dominos Koutu")
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
