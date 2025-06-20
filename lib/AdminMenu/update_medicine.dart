import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UpdateMedicinePage extends StatefulWidget {
  final DocumentSnapshot medicine;

  const UpdateMedicinePage({super.key, required this.medicine});

  @override
  State<UpdateMedicinePage> createState() => _UpdateMedicinePageState();
}

class _UpdateMedicinePageState extends State<UpdateMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _prescriptionController;
  bool _prescriptionRequired = false;
  File? _newImageFile;
  late String _imageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.medicine.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name']);
    _priceController = TextEditingController(text: data['price'].toString());
    _stockController = TextEditingController(text: data['stock'].toString());
    _prescriptionController = TextEditingController(text: data['prescription_details'] ?? '');
    _prescriptionRequired = data['prescription_required'] ?? false;
    _imageUrl = data['image_url'];
  }

  Future<void> _pickNewImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  Future<String> _uploadNewImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('medicine_images/$fileName');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _updateMedicine() async {
    final adminId = widget.medicine.reference.parent.parent!.id;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = _imageUrl;
      if (_newImageFile != null) {
        imageUrl = await _uploadNewImage(_newImageFile!);
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'prescription_required': _prescriptionRequired,
        'prescription_details': _prescriptionController.text.trim(),
        'image_url': imageUrl,
        'admin_id': adminId,
      };

      // Update subcollection under admin
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('medicines')
          .doc(widget.medicine.id)
          .update(updatedData);

      // Update global medicine collection
      await FirebaseFirestore.instance
          .collection('medicines')
          .doc(widget.medicine.id)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickNewImage,
                child: _newImageFile != null
                    ? Image.file(_newImageFile!, height: 150)
                    : Image.network(_imageUrl, height: 150),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (RM)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Enter a valid price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Enter a valid stock quantity' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Prescription Required'),
                value: _prescriptionRequired,
                onChanged: (val) => setState(() => _prescriptionRequired = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Prescription Details',
                  hintText: 'Describe any prescription requirements',
                ),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _updateMedicine,
                child: const Text('Update Medicine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
