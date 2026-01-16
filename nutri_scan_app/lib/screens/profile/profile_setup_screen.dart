import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/profile_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _gender = 'Male';
  String _fitnessGoal = 'Maintain'; // Default
  List<String> _healthIssues = [];
  List<String> _allergies = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfile();
    
    if (profileProvider.hasProfile) {
      final profile = profileProvider.profile!;
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _weightController.text = profile.weight.toString();
      _heightController.text = profile.height.toString();
      _locationController.text = profile.location;
      _gender = profile.gender;
      _fitnessGoal = profile.fitnessGoal;
      _healthIssues = List.from(profile.healthIssues);
      _allergies = List.from(profile.allergies);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    final profileData = {
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text),
      'gender': _gender,
      'weight': double.parse(_weightController.text),
      'height': double.parse(_heightController.text),
      'location': _locationController.text.trim().isEmpty ? 'India' : _locationController.text.trim(),
      'fitness_goal': _fitnessGoal,
      'health_issues': _healthIssues,
      'allergies': _allergies,
      'requirements': 1, // trigger recalc
    };

    final success = await profileProvider.createProfile(profileData);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error ?? 'Failed to save profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateBMI(double weight, double height) {
    if (height == 0) return 0;
    final heightM = height / 100;
    return weight / (heightM * heightM);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    double? bmi;
    String? bmiCategory;
    
    if (_weightController.text.isNotEmpty && _heightController.text.isNotEmpty) {
      try {
        final weight = double.parse(_weightController.text);
        final height = double.parse(_heightController.text);
        bmi = _calculateBMI(weight, height);
        bmiCategory = _getBMICategory(bmi);
      } catch (e) {
        // Invalid input
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 1 || age > 120) {
                            return 'Please enter a valid age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (State/Country)',
                          hintText: 'e.g., India, USA, Gujarat',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _gender = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Body Measurements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 1 || weight > 500) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: Icon(Icons.height),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height < 1 || height > 300) {
                            return 'Please enter a valid height';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _fitnessGoal,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Goal',
                          prefixIcon: Icon(Icons.fitness_center),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Maintain', 'Bulk (Gain Weight)', 'Cut (Lose Weight)']
                            .map((goal) => DropdownMenuItem(
                                  value: goal,
                                  child: Text(goal),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _fitnessGoal = value!);
                        },
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 24),
                        const Text("BMI Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade300, Colors.green, Colors.orange, Colors.red],
                                stops: const [0.2, 0.45, 0.7, 1.0],
                              ),
                            ),
                            child: Stack(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Scale BMI 10-40 into width
                                    double pos = ((bmi! - 10) / (40 - 10)).clamp(0.0, 1.0);
                                    return Align(
                                      alignment: Alignment(pos * 2 - 1, 0), // -1 to 1 range
                                      child: Container(
                                        width: 4, 
                                        height: 30, 
                                        color: Colors.black,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Underweight", style: TextStyle(fontSize: 10)),
                              Text("Normal", style: TextStyle(fontSize: 10)),
                              Text("Overweight", style: TextStyle(fontSize: 10)),
                              Text("Obese", style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BMI:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${bmi.toStringAsFixed(1)} ($bmiCategory)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Health Issues (Optional)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'None',
                          'Diabetes',
                          'Hypertension',
                          'Heart Disease',
                          'Obesity',
                        ].map((issue) {
                          final isSelected = _healthIssues.contains(issue);
                          return FilterChip(
                            label: Text(issue),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (issue == 'None') {
                                    _healthIssues = ['None'];
                                  } else {
                                    _healthIssues.remove('None');
                                    _healthIssues.add(issue);
                                  }
                                } else {
                                  _healthIssues.remove(issue);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Allergies (Optional)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'None',
                          'Nuts',
                          'Dairy',
                          'Gluten',
                          'Seafood',
                        ].map((allergy) {
                          final isSelected = _allergies.contains(allergy);
                          return FilterChip(
                            label: Text(allergy),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (allergy == 'None') {
                                    _allergies = ['None'];
                                  } else {
                                    _allergies.remove('None');
                                    _allergies.add(allergy);
                                  }
                                } else {
                                  _allergies.remove(allergy);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  return ElevatedButton(
                    onPressed: profileProvider.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: profileProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
