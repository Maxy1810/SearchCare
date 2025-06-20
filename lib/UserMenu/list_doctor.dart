import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_consult.dart';
import 'consult_status.dart';

class ListDoctorPage extends StatefulWidget {
  const ListDoctorPage({super.key});

  @override
  State<ListDoctorPage> createState() => _ListDoctorPageState();
}

class _ListDoctorPageState extends State<ListDoctorPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE6F5E6),
              Color(0xFFB2D8B2),
              Color(0xFF88B04B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App logo and title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/search_care.jpeg',
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Doctors List',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by expertise or workplace',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Doctor list from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final doctors = snapshot.data!.docs;

                    // Filter doctors by expertise or workplace
                    final filteredDoctors = doctors.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final expertise = (data['expertise'] ?? '').toString().toLowerCase();
                      final workplace = (data['workplace'] ?? '').toString().toLowerCase();
                      return expertise.contains(_searchQuery) || workplace.contains(_searchQuery);
                    }).toList();

                    if (filteredDoctors.isEmpty) {
                      return const Center(
                        child: Text(
                          "No doctors match your search.",
                          style: TextStyle(color: Colors.black87),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDoctors[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final fullName = data['fullName'] ?? 'No Name';
                        final workplace = data['workplace'] ?? 'Unknown';
                        final expertise = data['expertise'] ?? 'Unknown';
                        final photoUrl = data['photoUrl'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage('assets/images/default_doctor.png') as ImageProvider,
                              radius: 25,
                            ),
                            title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Workplace: $workplace"),
                                Text("Expertise: $expertise"),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookConsultPage(
                                              doctorId: doc.id,
                                              doctorName: fullName,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                      child: const Text('Book'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ConsultStatusPage(
                                              doctorId: doc.id,
                                              doctorName: fullName,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Status',
                                        style: TextStyle(color: Colors.teal),
                                      ),
                                    ),
                                  ],
                                )
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
      ),
    );
  }
}
