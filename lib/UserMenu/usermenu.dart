import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:search_care/UserMenu/view_healthy_tips_page.dart';
import 'buy_medicine.dart';
import 'cart_screen.dart';
import 'package:search_care/UserMenu/doctor_list.dart' as appointment;
import 'package:search_care/UserMenu/list_doctor.dart' as consult;
import 'search_location.dart';
import 'search_symptoms.dart';
import 'setting_page.dart';

class UserMenu extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onLogout;

  const UserMenu({super.key, required this.data, required this.onLogout});

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  late Map<String, dynamic> _userData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _userData = widget.data;
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data()!;
      });
    } else {
      final docDoctor = await _firestore.collection('doctors').doc(uid).get();
      if (docDoctor.exists) {
        setState(() {
          _userData = docDoctor.data()!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _userData['photoUrl'] as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Translucent background logo
            Center(
              child: Opacity(
                opacity: 0.06,
                child: Image.asset(
                  'assets/images/search_care.jpeg',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text('Main Menu', style: TextStyle(color: Colors.black)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.black),
                        tooltip: 'View Cart',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black),
                        tooltip: 'Logout',
                        onPressed: widget.onLogout,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingPage()),
                            );
                            await _loadUserData(); // Refresh user data after settings page
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Welcome, ${_userData['fullName']}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildMenuCard(
                            icon: Icons.medication,
                            label: 'Buy Medicine',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BuyMedicinePage()),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.search,
                            label: 'Search Symptoms',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchSymptomsPage()));
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.calendar_today,
                            label: 'Book Appointment',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const appointment.DoctorListPage()),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.video_call,
                            label: 'Book Consultations',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const consult.ListDoctorPage()),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.health_and_safety,
                            label: 'Healthy Tips',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ViewHealthyTipsPage()),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.map,
                            label: 'Search Location',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchLocationPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.teal),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
