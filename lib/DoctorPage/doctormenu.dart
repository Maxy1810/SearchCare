import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:search_care/DoctorPage/view_app.dart';
import 'package:search_care/DoctorPage/view_consult.dart';
import 'doctor_setting.dart';

class DoctorMenu extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onLogout;

  const DoctorMenu({super.key, required this.data, required this.onLogout});

  @override
  State<DoctorMenu> createState() => _DoctorMenuState();
}

class _DoctorMenuState extends State<DoctorMenu> {
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
        final url = doc.data()?['photoUrl'];

        setState(() {
          profileImageUrl = url;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading profile image: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.data['fullName'] ?? 'Unknown';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Translucent logo in the center
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/search_care.jpeg',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/search_care.jpeg', fit: BoxFit.contain),
                  ),
                  title: const Text('Doctor Dashboard'),
                  actions: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorSettingsPage(data: widget.data),
                          ),
                        );
                        _loadProfileImage(); // Reload profile image after settings update
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: widget.onLogout,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome Dr. $fullName',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildGridTile(
                        icon: Icons.calendar_today,
                        title: 'View Appointments',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAppointmentsPage(
                                doctorId: FirebaseAuth.instance.currentUser!.uid,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildGridTile(
                        icon: Icons.chat,
                        title: 'View Consultations',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewConsultationsPage(
                                doctorId: FirebaseAuth.instance.currentUser!.uid,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue[800]),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
