import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  String? _photoUrl;
  String? _userId;
  String? _role;

  bool _isLoading = true;
  String? _error;
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in.';
          _isLoading = false;
        });
        return;
      }
      _userId = user.uid;

      DocumentSnapshot<Map<String, dynamic>> doc;

      doc = await _firestore.collection('users').doc(_userId).get();
      if (!doc.exists) {
        doc = await _firestore.collection('doctors').doc(_userId).get();
        if (!doc.exists) {
          setState(() {
            _error = 'User data not found.';
            _isLoading = false;
          });
          return;
        } else {
          _role = 'doctor';
        }
      } else {
        _role = 'user';
      }

      final data = doc.data()!;
      _fullNameController.text = data['fullName'] ?? '';
      _emailController.text = data['email'] ?? user.email ?? '';
      _phoneController.text = data['phone'] ?? '';
      _cityController.text = data['city'] ?? '';
      _countryController.text = data['country'] ?? '';
      _photoUrl = data['photoUrl'];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = _storage.ref().child('profile_images/$_userId.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (_userId == null || _role == null) return;

    setState(() => _isLoading = true);

    try {
      final collection = _role == 'doctor' ? 'doctors' : 'users';

      String? imageUrl = _photoUrl;

      if (_newImage != null) {
        final uploaded = await _uploadImage(_newImage!);
        if (uploaded != null) imageUrl = uploaded;
      }

      await _firestore.collection(collection).doc(_userId).update({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'photoUrl': imageUrl,
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Saved'),
          content: const Text('Your changes have been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.blue),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.blue),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final imageProvider = _newImage != null
        ? FileImage(_newImage!)
        : (_photoUrl != null && _photoUrl!.isNotEmpty
        ? NetworkImage(_photoUrl!) as ImageProvider
        : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.blue),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset('assets/images/search_care.jpeg', width: 250),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: imageProvider,
                      backgroundColor: Colors.grey[300],
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Tap to change profile picture", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 30),
                  _buildTextField(label: 'Full Name', controller: _fullNameController),
                  const SizedBox(height: 20),
                  _buildTextField(label: 'Email', controller: _emailController, enabled: false),
                  const SizedBox(height: 20),
                  _buildTextField(label: 'Phone Number', controller: _phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildTextField(label: 'City', controller: _cityController),
                  const SizedBox(height: 20),
                  _buildTextField(label: 'Country', controller: _countryController),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: _isLoading ? null : _saveChanges,
                      child: const Text('Save Changes'),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
