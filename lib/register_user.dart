import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String _userFullName = '', _idNumber = '', _address = '';
  bool _hasCriminalRecord = false, _hasMedicalHistory = false;
  String _gender = 'Male';

  String _doctorFullName = '', _medicalLicenseNumber = '', _expertise = '', _workplace = '';

  bool? _isDoctor;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_profileImage!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  bool _isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^\+?\d{7,15}$');
    return regex.hasMatch(phone);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile image')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final photoUrl = await _uploadProfileImage(uid);

      if (photoUrl == null) {
        await userCredential.user!.delete();
        setState(() => _isLoading = false);
        return;
      }

      if (_isDoctor == true) {
        await firestore.collection('doctors').doc(uid).set({
          'fullName': _doctorFullName,
          'medicalLicenseNumber': _medicalLicenseNumber,
          'expertise': _expertise,
          'workplace': _workplace,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'gender': _gender,
          'photoUrl': photoUrl,
          'uid': uid,
          'role': 'doctor',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await firestore.collection('users').doc(uid).set({
          'username': _usernameController.text.trim(),
          'fullName': _userFullName,
          'idNumber': _idNumber,
          'address': _address,
          'hasCriminalRecord': _hasCriminalRecord,
          'hasMedicalHistory': _hasMedicalHistory,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'gender': _gender,
          'photoUrl': photoUrl,
          'uid': uid,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Registration Successful"),
          content: const Text("Account created. Please log in."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      final error = switch (e.code) {
        'email-already-in-use' => 'Email is already registered.',
        'invalid-email' => 'Invalid email address.',
        'weak-password' => 'Password should be at least 6 characters.',
        _ => 'Authentication error: ${e.message}',
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Container(
          width: double.infinity,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB2EBF2), Color(0xFFB2DFDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: _isDoctor == null
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (_isDoctor == null) ...[
                          Center(
                            child: Image.asset(
                              'assets/images/search_care.jpeg',
                              height: 120,
                              width: 120,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              'Select Account Type',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () => setState(() => _isDoctor = false),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Register as User', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => setState(() => _isDoctor = true),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Register as Doctor', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Already have an account? Login here"),
                          ),
                        ],
                        if (_isDoctor != null)
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Image.asset(
                                    'assets/images/search_care.jpeg',
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _isDoctor! ? "Doctor Registration" : "User Registration",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage: _profileImage != null
                                          ? FileImage(_profileImage!)
                                          : null,
                                      child: _profileImage == null
                                          ? const Icon(Icons.camera_alt, size: 40)
                                          : null,
                                    ),
                                  ),
                                ),
                                if (_isUploadingImage) ...[
                                  const SizedBox(height: 8),
                                  const Center(child: CircularProgressIndicator()),
                                ],
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                      labelText: 'Email', border: OutlineInputBorder()),
                                  validator: (value) =>
                                  value!.isEmpty ? 'Email is required' : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Password', border: OutlineInputBorder()),
                                  validator: (value) =>
                                  value!.length < 6 ? 'Minimum 6 characters' : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                      labelText: 'Phone Number', border: OutlineInputBorder()),
                                  validator: (value) => !_isValidPhoneNumber(value!.trim())
                                      ? 'Enter valid phone number'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                      labelText: 'City', border: OutlineInputBorder()),
                                  validator: (value) => value!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _countryController,
                                  decoration: const InputDecoration(
                                      labelText: 'Country', border: OutlineInputBorder()),
                                  validator: (value) => value!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Gender:'),
                                    const SizedBox(width: 10),
                                    DropdownButton<String>(
                                      value: _gender,
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      ],
                                      onChanged: (value) =>
                                          setState(() => _gender = value ?? 'Male'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (_isDoctor == true) ...[
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Full Name', border: OutlineInputBorder()),
                                    onSaved: (value) => _doctorFullName = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'License Number: MD-',
                                        border: OutlineInputBorder()),
                                    onSaved: (value) => _medicalLicenseNumber = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Expertise', border: OutlineInputBorder()),
                                    onSaved: (value) => _expertise = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Workplace', border: OutlineInputBorder()),
                                    onSaved: (value) => _workplace = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                ] else if (_isDoctor == false) ...[
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Username', border: OutlineInputBorder()),
                                    controller: _usernameController,
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Full Name', border: OutlineInputBorder()),
                                    onSaved: (value) => _userFullName = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'ID Number', border: OutlineInputBorder()),
                                    onSaved: (value) => _idNumber = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Address', border: OutlineInputBorder()),
                                    onSaved: (value) => _address = value ?? '',
                                    validator: (value) => value!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _hasCriminalRecord,
                                        onChanged: (v) =>
                                            setState(() => _hasCriminalRecord = v ?? false),
                                      ),
                                      const Text('Have criminal record'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _hasMedicalHistory,
                                        onChanged: (v) =>
                                            setState(() => _hasMedicalHistory = v ?? false),
                                      ),
                                      const Text('Have medical history'),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 30),
                                _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                  onPressed: _register,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Text(
                                      'Register',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => setState(() => _isDoctor = null),
                                  child: const Text("Back to account type selection"),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}