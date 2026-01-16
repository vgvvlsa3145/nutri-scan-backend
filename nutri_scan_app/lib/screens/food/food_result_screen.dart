import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/food_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_model.dart';
import '../diet/diet_plan_screen.dart';

class FoodResultScreen extends StatelessWidget {
  const FoodResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Analysis'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detected Foods
            if (foodProvider.detectedFoods.isNotEmpty) ...[
              const Text(
                'Detected Foods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...foodProvider.detectedFoods.map((food) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(food.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Confidence: ${(food.confidence * 100).toStringAsFixed(1)}%'),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: food.source == 'gemini'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              food.source == 'gemini'
                                  ? '✨ Advanced AI Brain'
                                  : '⚡ YOLO Mode',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: food.source == 'gemini'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: food.nutrition != null
                          ? Text(
                              '${food.nutrition!.calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // Nutrition Summary
            if (foodProvider.totalNutrition != null) ...[
              const Text(
                'Nutrition Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildNutritionRow(
                        'Calories',
                        '${foodProvider.totalNutrition!.calories.toStringAsFixed(0)} kcal',
                      ),
                      _buildNutritionRow(
                        'Protein',
                        '${foodProvider.totalNutrition!.protein.toStringAsFixed(1)}g',
                      ),
                      _buildNutritionRow(
                        'Carbs',
                        '${foodProvider.totalNutrition!.carbs.toStringAsFixed(1)}g',
                      ),
                      _buildNutritionRow(
                        'Fat',
                        '${foodProvider.totalNutrition!.fat.toStringAsFixed(1)}g',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pie Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Macronutrient Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(
                              foodProvider.totalNutrition!,
                            ),
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Vitamins & Minerals Analysis (New)
              if (foodProvider.totalNutrition != null) ...[
                 const Text(
                  'Micronutrients Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMicroRow('Vitamin A', foodProvider.totalNutrition!.vitaminA, 900, 'mcg', Colors.orange), // 900mcg RAE for adults
                        _buildMicroRow('Vitamin C', foodProvider.totalNutrition!.vitaminC, 90, 'mg', Colors.yellow.shade700), // 90mg for adults
                        _buildMicroRow('Calcium', foodProvider.totalNutrition!.calcium, 1300, 'mg', Colors.blueGrey), // 1300mg
                        _buildMicroRow('Iron', foodProvider.totalNutrition!.iron, 18, 'mg', Colors.brown), // 18mg
                        _buildMicroRow('Sodium', foodProvider.totalNutrition!.sodium, 2300, 'mg', Colors.grey), // 2300mg limit
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // RDA Analysis
            if (foodProvider.rdaAnalysis != null &&
                profileProvider.hasProfile) ...[
              const Text(
                'RDA Comparison',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildRDARow(
                        'Calories',
                        foodProvider.rdaAnalysis!.nutrients['calories']!,
                      ),
                      _buildRDARow(
                        'Protein',
                        foodProvider.rdaAnalysis!.nutrients['protein']!,
                      ),
                      _buildRDARow(
                        'Carbs',
                        foodProvider.rdaAnalysis!.nutrients['carbs']!,
                      ),
                      _buildRDARow(
                        'Fat',
                        foodProvider.rdaAnalysis!.nutrients['fat']!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Suggestions
              if (foodProvider.rdaAnalysis!.suggestions.increase.isNotEmpty ||
                  foodProvider.rdaAnalysis!.suggestions.reduce.isNotEmpty) ...[
                const Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (foodProvider.rdaAnalysis!.suggestions.increase.isNotEmpty) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Increase:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...foodProvider.rdaAnalysis!.suggestions.increase
                              .map((item) => Text(
                                    '• ${item.nutrient}: Need ${item.needed.toStringAsFixed(1)} more',
                                  )),
                        ],
                      ),
                    ),
                  ),
                ],
                if (foodProvider.rdaAnalysis!.suggestions.reduce.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reduce:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...foodProvider.rdaAnalysis!.suggestions.reduce
                              .map((item) => Text(
                                    '• ${item.nutrient}: Reduce by ${item.excess?.toStringAsFixed(1) ?? 0}',
                                  )),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                
                // Manual Entry Actions
                if (foodProvider.detectedFoods.isNotEmpty && 
                    foodProvider.detectedFoods.first.source == 'manual')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await foodProvider.logManualEntry();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success 
                                ? 'Food Log Saved Successfully!' 
                                : 'Failed to save log: ${foodProvider.error}'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success) {
                             // Correctly navigate back or clear manual entry context
                             Navigator.of(context).pop(); // Go back to Manual Entry
                             Navigator.of(context).pop(); // Go back to Home (optional, checks stack)
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save to Daily Log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                ElevatedButton(
                  onPressed: () async {
                    // Generate diet plan
                    try {
                      await ApiService.generateDietPlan(
                        rdaAnalysis: foodProvider.rdaAnalysis != null
                            ? {
                                'overall_status':
                                    foodProvider.rdaAnalysis!.overallStatus,
                                'suggestions': {
                                  'increase': foodProvider
                                      .rdaAnalysis!.suggestions.increase
                                      .map((e) => {
                                            'nutrient': e.nutrient,
                                            'current': e.current,
                                            'target': e.target,
                                            'needed': e.needed,
                                          })
                                      .toList(),
                                  'reduce': foodProvider
                                      .rdaAnalysis!.suggestions.reduce
                                      .map((e) => {
                                            'nutrient': e.nutrient,
                                            'current': e.current,
                                            'target': e.target,
                                            'excess': e.excess,
                                          })
                                      .toList(),
                                },
                              }
                            : null,
                      );
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DietPlanScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Generate Diet Plan'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(NutritionData nutrition) {
    final proteinCal = nutrition.protein * 4;
    final carbsCal = nutrition.carbs * 4;
    final fatCal = nutrition.fat * 9;
    final total = proteinCal + carbsCal + fatCal;

    if (total == 0) return [];

    return [
      PieChartSectionData(
        value: proteinCal,
        title: '${((proteinCal / total) * 100).toStringAsFixed(0)}%',
        color: Colors.blue,
        radius: 60,
      ),
      PieChartSectionData(
        value: carbsCal,
        title: '${((carbsCal / total) * 100).toStringAsFixed(0)}%',
        color: Colors.green,
        radius: 60,
      ),
      PieChartSectionData(
        value: fatCal,
        title: '${((fatCal / total) * 100).toStringAsFixed(0)}%',
        color: Colors.orange,
        radius: 60,
      ),
    ];
  }

  Widget _buildNutritionRow(String label, String value) {
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

  Widget _buildRDARow(String label, NutrientAnalysis nutrientAnalysis) {
    Color statusColor;
    IconData statusIcon;
    if (nutrientAnalysis.status == 'low') {
      statusColor = Colors.orange;
      statusIcon = Icons.arrow_downward;
    } else if (nutrientAnalysis.status == 'high') {
      statusColor = Colors.red;
      statusIcon = Icons.arrow_upward;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Row(
            children: [
              Text(
                '${nutrientAnalysis.consumed.toStringAsFixed(0)} / ${nutrientAnalysis.target.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(statusIcon, color: statusColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroRow(String label, double val, double target, String unit, Color color) {
     double percent = (val / target).clamp(0.0, 1.0);
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text("${val.toStringAsFixed(1)} / $target $unit", style: const TextStyle(color: Colors.grey)),
             ],
           ),
           const SizedBox(height: 5),
           ClipRRect(
             borderRadius: BorderRadius.circular(4),
             child: LinearProgressIndicator(
               value: percent,
               minHeight: 8,
               backgroundColor: color.withOpacity(0.1),
               valueColor: AlwaysStoppedAnimation<Color>(color),
             ),
           ),
         ],
       ),
    );
  }
}

