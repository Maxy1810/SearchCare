import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DoctorSettingsPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DoctorSettingsPage({super.key, required this.data});

  @override
  State<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends State<DoctorSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _workplaceController;
  late TextEditingController _expertiseController;
  String? _photoUrl;
  File? _imageFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestProfile();
  }

  Future<void> _loadLatestProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();

    final data = doc.data()!;
    setState(() {
      _nameController = TextEditingController(text: data['fullName']);
      _workplaceController = TextEditingController(text: data['workplace']);
      _expertiseController = TextEditingController(text: data['expertise']);
      _photoUrl = data['photoUrl'];
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadImageAndGetUrl(String uid) async {
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_imageFile!);
      _photoUrl = await ref.getDownloadURL();
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _uploadImageAndGetUrl(uid);

      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'fullName': _nameController.text,
        'workplace': _workplaceController.text,
        'expertise': _expertiseController.text,
        'photoUrl': _photoUrl ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      await _loadLatestProfile(); // Refresh UI after save
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Translucent app logo
            Center(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/search_care.jpeg', // replace with your logo path
                  width: 300,
                  height: 300,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? NetworkImage(_photoUrl!) as ImageProvider
                                : const AssetImage('assets/default_profile.png'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    TextFormField(
                      controller: _workplaceController,
                      decoration: const InputDecoration(labelText: 'Workplace'),
                    ),
                    TextFormField(
                      controller: _expertiseController,
                      decoration: const InputDecoration(labelText: 'Expertise'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
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
