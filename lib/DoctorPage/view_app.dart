import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAppointmentsPage extends StatefulWidget {
  final String doctorId;

  const ViewAppointmentsPage({super.key, required this.doctorId});

  @override
  State<ViewAppointmentsPage> createState() => _ViewAppointmentsPageState();
}

class _ViewAppointmentsPageState extends State<ViewAppointmentsPage> {
  String _selectedFilter = 'pending'; // default filter
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = fetchAppointments();
  }

  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    final userDocs = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> appointments = [];

    for (var userDoc in userDocs.docs) {
      final apps = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .get();

      for (var app in apps.docs) {
        appointments.add({
          ...app.data(),
          'userId': userDoc.id,
          'appointmentId': app.id,
        });
      }
    }

    return appointments;
  }

  Future<void> updateStatus(String userId, String appId, String status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .doc(appId)
        .update({'status': status});
    setState(() {
      _appointmentsFuture = fetchAppointments(); // Refresh list
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
        title: const Text('Received Appointments'),
        backgroundColor: const Color(0xFF69F0AE),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF69F0AE), Color(0xFFB2EBF2)],
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
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No appointments received.'));
                  }

                  final filtered = snapshot.data!
                      .where((app) => (app['status'] ?? 'pending') == _selectedFilter)
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No $_selectedFilter appointments.'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      final status = app['status'] ?? 'pending';
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
                              Text("Patient: ${app['fullName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("Date: ${_formatDate(app['date'])}"),
                              Text("Time: ${app['time']}"),
                              Text("Method: ${app['method']}"),
                              Text("Reason: ${app['reason']}"),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(status.toUpperCase(), style: TextStyle(color: statusColor)),
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
                                      onPressed: () => updateStatus(app['userId'], app['appointmentId'], 'confirmed'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      label: const Text("Reject"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => updateStatus(app['userId'], app['appointmentId'], 'rejected'),
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
