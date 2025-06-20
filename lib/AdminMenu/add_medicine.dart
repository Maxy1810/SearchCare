import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String> _uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('medicine_images/$fileName');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image.")),
        );
        return;
      }

      setState(() => _isUploading = true);

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('User not logged in.');
        }

        final adminId = currentUser.uid;
        final imageUrl = await _uploadImage(_imageFile!);
        final prescriptionDetails = _prescriptionController.text.trim();

        final medicineData = {
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'stock': int.parse(_stockController.text.trim()),
          'prescription_required': prescriptionDetails.isNotEmpty,
          'prescription_details': prescriptionDetails,
          'image_url': imageUrl,
          'admin_id': adminId,
          'created_at': FieldValue.serverTimestamp(),
        };

        // Add to global medicines collection
        final docRef = await FirebaseFirestore.instance
            .collection('medicines')
            .add(medicineData);

        // Add the same data to admin subcollection (including the new global doc ID)
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId)
            .collection('medicines')
            .doc(docRef.id)
            .set(medicineData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully!')),
        );

        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
          _prescriptionController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Medicine")),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD7BDE2), // light purple
              Color(0xFFFFCC80), // light orange
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/search_care.jpeg',
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: _imageFile != null
                          ? Image.file(_imageFile!, height: 150)
                          : Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Text("Tap to select image")),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Medicine Name'),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter medicine name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price (RM)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || double.tryParse(value) == null
                          ? 'Enter a valid price'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || int.tryParse(value) == null
                          ? 'Enter a valid stock quantity'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _prescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Prescription Details (if any)',
                        hintText: 'Enter prescription instructions or leave blank',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _isUploading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _saveMedicine,
                      child: const Text('Save Medicine'),
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
