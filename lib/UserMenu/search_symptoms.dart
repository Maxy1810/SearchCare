import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchSymptomsPage extends StatefulWidget {
  const SearchSymptomsPage({super.key});

  @override
  State<SearchSymptomsPage> createState() => _SearchSymptomsPageState();
}

class _SearchSymptomsPageState extends State<SearchSymptomsPage> {
  final TextEditingController _symptomController = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  void _search() async {
    final query = _symptomController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance.collection('disease').get();

    final matches = snapshot.docs.where((doc) {
      final data = doc.data();
      final symptoms = List<String>.from(data['symptoms'] ?? []);
      return symptoms.any((s) => s.toLowerCase().contains(query));
    }).map((doc) => doc.data()).toList();

    setState(() {
      _results = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Symptoms'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          // Gradient background with translucent logo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8BBD0), Color(0xFFE1BEE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Center(
                child: Image.asset(
                  'assets/images/search_care.jpeg', // Make sure this is added in pubspec.yaml
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    labelText: 'Enter symptom',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _results.isEmpty
                      ? const Center(
                    child: Text(
                      "No matching diseases found",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final data = _results[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['disease'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Symptoms: ${(data['symptoms'] as List).join(', ')}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
