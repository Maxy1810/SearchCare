import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:search_care/AdminMenu/add_medicine.dart';
import 'package:search_care/AdminMenu/update_lifestyle.dart';
import 'package:search_care/AdminMenu/update_symptoms.dart';
import 'package:search_care/AdminMenu/view_medicine.dart';
import 'package:search_care/AdminMenu/update_location.dart';
import 'package:search_care/login.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _isAdmin = adminDoc.exists;
            _adminEmail = user.email;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied or Firestore error')),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  final List<Map<String, dynamic>> _adminOptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminOptions.clear();
    _adminOptions.addAll([
      {
        'title': 'Add Medicines',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicinePage()));
        }
      },
      {
        'title': 'View Medicine',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewMedicinePage()));
        }
      },
      {
        'title': 'Update Healthy Lifestyle',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateLifestylePage()));
        }
      },
      {
        'title': 'Update Symptoms',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateSymptomsPage()));
        }
      },
      {
        'title': 'Update Location',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateLocationPage()));
        }
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text("Access denied. You're not an admin.")),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD7BDE2), Color(0xFFF5B7B1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Center translucent logo as background
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

            // Foreground content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with logo and logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/search_care.jpeg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Sign Out',
                          onPressed: _signOut,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome, Admin $_adminEmail",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _adminOptions.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 3 / 2,
                        ),
                        itemBuilder: (context, index) {
                          final option = _adminOptions[index];
                          return GestureDetector(
                            onTap: option['onTap'],
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  option['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
