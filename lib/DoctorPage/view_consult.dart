import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewConsultationsPage extends StatefulWidget {
  final String doctorId;

  const ViewConsultationsPage({super.key, required this.doctorId});

  @override
  State<ViewConsultationsPage> createState() => _ViewConsultationsPageState();
}

class _ViewConsultationsPageState extends State<ViewConsultationsPage> {
  String _selectedFilter = 'pending'; // Default selected status
  late Future<List<Map<String, dynamic>>> _consultationsFuture;

  @override
  void initState() {
    super.initState();
    _consultationsFuture = fetchConsultations();
  }

  Future<List<Map<String, dynamic>>> fetchConsultations() async {
    final userDocs = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> consultations = [];

    for (var userDoc in userDocs.docs) {
      final consults = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('consultations')
          .where('doctorId', isEqualTo: widget.doctorId)
          .get();

      for (var consult in consults.docs) {
        consultations.add({
          ...consult.data(),
          'userId': userDoc.id,
          'consultationId': consult.id,
        });
      }
    }
    return consultations;
  }

  Future<void> updateStatus(String userId, String consultId, String status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('consultations')
        .doc(consultId)
        .update({'status': status});
    setState(() {
      _consultationsFuture = fetchConsultations();
    });
  }

  Widget _buildFilterButton(String label, String value, Color color) {
    final bool isSelected = _selectedFilter == value;

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Consultations'),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF7986CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildFilterButton('Pending', 'pending', Colors.orange),
                  const SizedBox(width: 8),
                  _buildFilterButton('Confirmed', 'confirmed', Colors.green),
                  const SizedBox(width: 8),
                  _buildFilterButton('Rejected', 'rejected', Colors.red),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _consultationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No consultations received.',
                            style: TextStyle(color: Colors.white)));
                  }

                  final filtered = snapshot.data!
                      .where((c) => (c['status'] ?? 'pending') == _selectedFilter)
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No $_selectedFilter consultations.',
                          style: const TextStyle(color: Colors.white)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final consult = filtered[index];
                      final status = consult['status'] ?? 'pending';
                      Color statusColor;

                      switch (status) {
                        case 'confirmed':
                          statusColor = Colors.green;
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Patient: ${consult['fullName']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("Date: ${_formatDate(consult['date'])}"),
                              Text("Time: ${consult['time']}"),
                              Text("Method: ${consult['method']}"),
                              Text("Reason: ${consult['reason']}"),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text("Status: ",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(status.toUpperCase(),
                                      style: TextStyle(color: statusColor)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (status == 'pending')
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text("Confirm"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () => updateStatus(
                                          consult['userId'],
                                          consult['consultationId'],
                                          'confirmed'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      label: const Text("Reject"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => updateStatus(
                                          consult['userId'],
                                          consult['consultationId'],
                                          'rejected'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
