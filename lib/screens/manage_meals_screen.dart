import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/financial_service.dart';

class ManageMealsScreen extends StatefulWidget {
  const ManageMealsScreen({super.key});

  @override
  State<ManageMealsScreen> createState() => _ManageMealsScreenState();
}

class _ManageMealsScreenState extends State<ManageMealsScreen> {
  final FinancialService _financialService = FinancialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _membersList = [];
  Map<String, int> _mealCounts = {};
  bool _isLoading = true;

  static const Color primary = Color(0xFF087F8C);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FF);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    String monthId = DateFormat('yyyy-MM').format(DateTime.now());
    
    QuerySnapshot memberSnap = await _firestore.collection('members').get();
    List<Map<String, dynamic>> members = [];
    
    for (var doc in memberSnap.docs) {
      members.add({'email': doc.id, 'name': doc['name'], 'role': doc['role']});
    }

    DocumentSnapshot mealSnap = await _firestore.collection('monthly_meals').doc(monthId).get();
    Map<String, int> counts = {};
    
    if (mealSnap.exists) {
      Map<String, dynamic> data = mealSnap.data() as Map<String, dynamic>;
      data.forEach((key, value) {
        counts[key] = (value as num).toInt();
      });
    }

    setState(() {
      _membersList = members;
      _mealCounts = counts;
      _isLoading = false;
    });
  }

  void _updateMeal(String email, int change) async {
    int current = _mealCounts.containsKey(email) ? _mealCounts[email]! : 30;
    int newValue = current + change;
    if (newValue < 0) newValue = 0;

    setState(() {
      _mealCounts[email] = newValue;
    });

    await _financialService.updateMealCount(email, newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('সদস্যদের মিল হিসাব', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _membersList.length,
              itemBuilder: (context, index) {
                final member = _membersList[index];
                final email = member['email'];
                final int currentMeals = _mealCounts.containsKey(email) ? _mealCounts[email]! : 30;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dark)),
                              const SizedBox(height: 4),
                              Text(email.split('@')[0], style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: pageBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, color: Color(0xFFFF4058), size: 20),
                                onPressed: () => _updateMeal(email, -1),
                              ),
                              Text('$currentMeals', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dark)),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, color: Color(0xFF0BB77A), size: 20),
                                onPressed: () => _updateMeal(email, 1),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
