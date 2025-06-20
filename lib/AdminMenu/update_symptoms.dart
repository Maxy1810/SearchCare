import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateSymptomsPage extends StatefulWidget {
  const UpdateSymptomsPage({super.key});

  @override
  State<UpdateSymptomsPage> createState() => _UpdateSymptomsPageState();
}

class _UpdateSymptomsPageState extends State<UpdateSymptomsPage> {
  final TextEditingController _diseaseController = TextEditingController();
  final List<TextEditingController> _symptomControllers =
  List.generate(7, (_) => TextEditingController());
  final ScrollController _scrollController = ScrollController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _editingOldDiseaseName;

  Future<void> _saveDisease() async {
    final disease = _diseaseController.text.trim();
    final symptoms = _symptomControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (disease.isEmpty || symptoms.isEmpty) return;

    final adminId = _auth.currentUser?.uid;
    if (adminId == null) return;

    final data = {
      'disease': disease,
      'symptoms': symptoms,
    };

    final globalRef = _firestore.collection('disease');
    final adminRef =
    _firestore.collection('admin').doc(adminId).collection('disease');

    // If editing and changed disease name, delete the old one
    if (_editingOldDiseaseName != null &&
        _editingOldDiseaseName != disease) {
      await globalRef.doc(_editingOldDiseaseName).delete();
      await adminRef.doc(_editingOldDiseaseName).delete();
    }

    // Save new or updated data
    await globalRef.doc(disease).set(data);
    await adminRef.doc(disease).set(data);

    _clearForm();
  }

  void _clearForm() {
    _editingOldDiseaseName = null;
    _diseaseController.clear();
    for (var controller in _symptomControllers) {
      controller.clear();
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    final diseaseName = data['disease'] ?? '';
    final symptoms = List<String>.from(data['symptoms'] ?? []);

    setState(() {
      _editingOldDiseaseName = diseaseName;
      _diseaseController.text = diseaseName;
      for (int i = 0; i < _symptomControllers.length; i++) {
        _symptomControllers[i].text =
        i < symptoms.length ? symptoms[i] : '';
      }
    });

    // Scroll to top to bring form into view
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _deleteDisease(String diseaseName) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) return;

    await _firestore.collection('disease').doc(diseaseName).delete();
    await _firestore
        .collection('admin')
        .doc(adminId)
        .collection('disease')
        .doc(diseaseName)
        .delete();
  }

  @override
  void dispose() {
    _diseaseController.dispose();
    _scrollController.dispose();
    for (var controller in _symptomControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Manage Diseases'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add or Edit Disease',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _diseaseController,
                decoration: const InputDecoration(labelText: 'Disease Name'),
              ),
              const SizedBox(height: 10),
              ...List.generate(7, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _symptomControllers[index],
                    decoration:
                    InputDecoration(labelText: 'Symptom ${index + 1}'),
                  ),
                );
              }),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDisease,
                  child: Text(_editingOldDiseaseName == null
                      ? 'Save Disease'
                      : 'Update Disease'),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Saved Diseases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('disease').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text("No diseases added yet.");
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Disease')),
                        DataColumn(label: Text('Symptoms')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final disease = data['disease'] ?? '';
                        final symptoms =
                        List<String>.from(data['symptoms'] ?? []);

                        return DataRow(cells: [
                          DataCell(Text(disease)),
                          DataCell(Text(symptoms.join(', '))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon:
                                const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _populateForm(data);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () async {
                                  final confirmed =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text('Delete "$disease"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await _deleteDisease(disease);
                                  }
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
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
