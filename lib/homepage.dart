import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Importing separate dashboards
import 'package:search_care/UserMenu/usermenu.dart';
import 'package:search_care/DoctorPage/doctormenu.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? role;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final firestore = FirebaseFirestore.instance;

    try {
      // Retry mechanism: max 5 attempts with 300ms delay
      for (int i = 0; i < 5; i++) {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          setState(() {
            role = userDoc.get('role');
            _profileData = userDoc.data();
            _isLoading = false;
          });
          return;
        }

        final doctorDoc = await firestore.collection('doctors').doc(uid).get();
        if (doctorDoc.exists) {
          setState(() {
            role = doctorDoc.get('role');
            _profileData = doctorDoc.data();
            _isLoading = false;
          });
          return;
        }

        // Wait before retrying
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // If no document found after retries
      setState(() {
        role = 'unknown';
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching role: $e");
      setState(() {
        role = 'error';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == 'doctor' && _profileData != null) {
      return DoctorMenu(data: _profileData!, onLogout: _logout);
    } else if (role == 'user' && _profileData != null) {
      return UserMenu(data: _profileData!, onLogout: _logout);
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: const Center(
          child: Text('Unknown role or user not found in database.'),
        ),
      );
    }
  }
}
