import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _dailyReport;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDailyReport();
  }

  Future<void> _loadDailyReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final report = await ApiService.getDailyReport(date: dateStr);
      setState(() {
        _dailyReport = report['report'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report: ${_selectedDate.toIso8601String().split('T')[0]}'),
        backgroundColor: const Color(0xFFFF6B35),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDailyReport,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _dailyReport == null
                  ? const Center(
                      child: Text('No report available for today'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Daily Nutrition Summary',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_dailyReport!['total_nutrition'] != null)
                                    ..._buildNutritionSummary(
                                      _dailyReport!['total_nutrition'],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          _buildSearchBox(),
                          const SizedBox(height: 16),
                          if (_dailyReport!['total_nutrition'] != null && 
                              _dailyReport!['total_nutrition']['scans'] != null)
                            _buildHistorySection(List.from(_dailyReport!['total_nutrition']['scans'])),
                          const SizedBox(height: 16),
                          if (_dailyReport!['insights'] != null &&
                              (_dailyReport!['insights'] as List).isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Health Insights',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...(_dailyReport!['insights'] as List)
                                        .map((insight) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.lightbulb,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(insight),
                                                  ),
                                                ],
                                              ),
                                            )),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildNutritionSummary(Map<String, dynamic> nutrition) {
    return [
      _buildSummaryRow('Calories', '${nutrition['calories']?.toStringAsFixed(0) ?? 0} kcal'),
      _buildSummaryRow('Protein', '${nutrition['protein']?.toStringAsFixed(1) ?? 0}g'),
      _buildSummaryRow('Carbs', '${nutrition['carbs']?.toStringAsFixed(1) ?? 0}g'),
      _buildSummaryRow('Fat', '${nutrition['fat']?.toStringAsFixed(1) ?? 0}g'),
      if (nutrition['fiber'] != null)
        _buildSummaryRow('Fiber', '${nutrition['fiber']?.toStringAsFixed(1) ?? 0}g'),
      if (nutrition['vitamin_a'] != null)
        _buildSummaryRow('Vitamin A', '${nutrition['vitamin_a']?.toStringAsFixed(1) ?? 0} mcg'),
      if (nutrition['vitamin_c'] != null)
        _buildSummaryRow('Vitamin C', '${nutrition['vitamin_c']?.toStringAsFixed(1) ?? 0} mg'),
      if (nutrition['calcium'] != null)
        _buildSummaryRow('Calcium', '${nutrition['calcium']?.toStringAsFixed(1) ?? 0} mg'),
      if (nutrition['iron'] != null)
        _buildSummaryRow('Iron', '${nutrition['iron']?.toStringAsFixed(1) ?? 0} mg'),
    ];
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search food in history...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildHistorySection(List<dynamic> scans) {
    if (scans.isEmpty) return const SizedBox.shrink();

    // Filter scans based on search query
    final filteredScans = scans.where((scan) {
      if (_searchQuery.isEmpty) return true;
      final foods = scan['foods'] as List;
      return foods.any((f) => f['name'].toString().toLowerCase().contains(_searchQuery));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Food History (Grouped by Scan)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (filteredScans.isEmpty)
           const Center(child: Padding(
             padding: EdgeInsets.all(20.0),
             child: Text('No matching food found in history'),
           )),
        ...filteredScans.map((scan) {
          String time = 'Unknown';
          if (scan['time'] != null && scan['time'] != 'Unknown') {
            try {
              final date = DateTime.parse(scan['time']).toLocal();
              time = DateFormat('hh:mm a').format(date);
            } catch (e) {
              time = scan['time'];
            }
          }
          final nutrition = scan['total_nutrition'] ?? {};
          final foods = scan['foods'] as List? ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header of the Scan Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Color(0xFFFF6B35)),
                          const SizedBox(width: 8),
                          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(
                        '${nutrition['calories']?.toStringAsFixed(0) ?? 0} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                      ),
                    ],
                  ),
                ),
                // List of Foods in this Scan
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: foods.map((f) {
                      final name = f['name'] ?? 'Unknown';
                      final qty = f['quantity'] ?? 100;
                      final foodCals = f['nutrition']?['calories'] ?? 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('• $name (${qty}g)', style: const TextStyle(fontSize: 14))),
                            Text('${foodCals.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Collapsible summary or detailed nutrients could go here
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      _buildMiniMacro('P', '${nutrition['protein']?.toStringAsFixed(1)}g', Colors.blue),
                      _buildMiniMacro('C', '${nutrition['carbs']?.toStringAsFixed(1)}g', Colors.green),
                      _buildMiniMacro('F', '${nutrition['fat']?.toStringAsFixed(1)}g', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMiniMacro(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
