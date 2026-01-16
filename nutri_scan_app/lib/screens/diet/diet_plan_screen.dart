import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  Map<String, dynamic>? _dietPlan;
  bool _isLoading = false;
  String? _error;

  String? _selectedMealTime;
  final List<String> _mealTypes = ['General', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    _loadDietPlan();
  }

  Future<void> _loadDietPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mealArg = _selectedMealTime == 'General' ? null : _selectedMealTime;
      final response = await ApiService.generateDietPlan(mealTime: mealArg);
      setState(() {
        _dietPlan = response['meal_plan'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan'),
        backgroundColor: const Color(0xFFFF6B35),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDietPlan,
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
                        onPressed: _loadDietPlan,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _dietPlan == null
                  ? const Center(
                      child: Text('No diet plan available'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Personalized Meal Plan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Meal Type Selector
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _mealTypes.map((type) {
                                final isSelected = (_selectedMealTime ?? 'General') == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFFF6B35),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedMealTime = type == 'General' ? null : type;
                                        });
                                        _loadDietPlan();
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildMealCard(
                            'Breakfast',
                            _dietPlan!['breakfast'] ?? [],
                            Icons.wb_sunny,
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildMealCard(
                            'Lunch',
                            _dietPlan!['lunch'] ?? [],
                            Icons.lunch_dining,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildMealCard(
                            'Dinner',
                            _dietPlan!['dinner'] ?? [],
                            Icons.dinner_dining,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          _buildMealCard(
                            'Snacks',
                            _dietPlan!['snacks'] ?? [],
                            Icons.fastfood,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMealCard(
    String title,
    List<dynamic> foods,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (foods.isEmpty)
              const Text(
                'No items suggested',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...foods.map((food) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            food.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
