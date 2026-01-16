import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_provider.dart';
import 'food_result_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final List<Map<String, TextEditingController>> _ingredientControllers = [];
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  String _selectedMealTime = 'Snack';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    // Auto-select meal time based on hour
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) _selectedMealTime = 'Breakfast';
    else if (hour >= 11 && hour < 16) _selectedMealTime = 'Lunch';
    else if (hour >= 16 && hour < 22) _selectedMealTime = 'Dinner';
    
    // Start with one row
    _addIngredientRow();
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
    }
  }

  // ... (existing methods _addIngredientRow, _removeIngredientRow, dispose)
  void _addIngredientRow() {
    setState(() {
      _ingredientControllers.add({
        'name': TextEditingController(),
        'weight': TextEditingController(),
      });
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientControllers[index]['name']?.dispose();
      _ingredientControllers[index]['weight']?.dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var controllerMap in _ingredientControllers) {
      controllerMap['name']?.dispose();
      controllerMap['weight']?.dispose();
    }
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredientControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    // Collect data
    final ingredients = <Map<String, dynamic>>[];
    for (var controllerMap in _ingredientControllers) {
      ingredients.add({
        'name': controllerMap['name']!.text.trim(),
        'weight': double.tryParse(controllerMap['weight']!.text) ?? 100.0,
      });
    }

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final success = await foodProvider.analyzeManualEntry(
      ingredients,
      date: _selectedDate,
      mealTime: _selectedMealTime,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FoodResultScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(foodProvider.error ?? 'Failed to analyze'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Context Selection (Date & Meal)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${_selectedDate.toLocal()}".split(' ')[0]),
                            const Icon(Icons.calendar_today, size: 20, color: Color(0xFFFF6B35)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMealTime,
                      decoration: const InputDecoration(
                        labelText: 'Meal Time',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _mealTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMealTime = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ingredientControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _ingredientControllers[index]['name'],
                              decoration: const InputDecoration(
                                labelText: 'Ingredient',
                                hintText: 'e.g., Chicken',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _ingredientControllers[index]['weight'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight (g)',
                                hintText: '100',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_ingredientControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeIngredientRow(index),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addIngredientRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<FoodProvider>(
                    builder: (context, foodProvider, _) {
                      return ElevatedButton(
                        onPressed: foodProvider.isLoading ? null : _analyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: foodProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text(
                                'Analyze Nutrition',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
