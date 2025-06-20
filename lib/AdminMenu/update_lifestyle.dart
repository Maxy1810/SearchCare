import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class UpdateLifestylePage extends StatelessWidget {
  const UpdateLifestylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'title': 'Food', 'icon': Icons.fastfood, 'collection': 'food_lifestyle'},
      {'title': 'Exercise', 'icon': Icons.fitness_center, 'collection': 'exercise_lifestyle'},
      {'title': 'Healthy Facts', 'icon': Icons.health_and_safety, 'collection': 'healthyfacts_lifestyle'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Update Lifestyle')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0E9), Color(0xFFE0CFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
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
            GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LifestyleCategoryPage(
                          title: category['title'],
                          collectionName: category['collection'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category['icon'], size: 60, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(category['title'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LifestyleCategoryPage extends StatefulWidget {
  final String title;
  final String collectionName;

  const LifestyleCategoryPage({required this.title, required this.collectionName, super.key});

  @override
  State<LifestyleCategoryPage> createState() => _LifestyleCategoryPageState();
}

class _LifestyleCategoryPageState extends State<LifestyleCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _activateAppCheck();
  }

  Future<void> _activateAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String> _uploadImage(File file) async {
    final fileName = '${widget.collectionName}_${DateTime.now().millisecondsSinceEpoch}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('lifestyle_images/${widget.collectionName}/$fileName');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('You must be signed in to upload.');

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) throw Exception('You do not have permission.');

      final imageUrl = await _uploadImage(_imageFile!);
      final textData = _textController.text.trim();

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .collection(widget.collectionName)
          .add({
        'category': widget.title,
        'text': textData,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} uploaded successfully!')),
      );

      _formKey.currentState!.reset();
      setState(() => _imageFile = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteItem(String docId, String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .collection(widget.collectionName)
          .doc(docId)
          .delete();

      await FirebaseStorage.instance.refFromURL(imageUrl).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthyFact = widget.collectionName == 'healthyfacts_lifestyle';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0E9), Color(0xFFE0CFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: _imageFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
                          )
                              : Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('Tap to select image')),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _textController,
                          decoration: InputDecoration(
                            labelText: isHealthyFact ? 'Enter healthy fact' : 'Enter details',
                            hintText: isHealthyFact
                                ? 'e.g., Drinking water boosts metabolism.'
                                : 'e.g., Eat fruits for breakfast.',
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: isHealthyFact ? 3 : 5,
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter some text' : null,
                        ),
                        const SizedBox(height: 30),
                        _isUploading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                          onPressed: _saveData,
                          icon: const Icon(Icons.upload),
                          label: Text('Upload ${widget.title} Info'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('Uploaded ${widget.title}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (user != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('admins')
                          .doc(user.uid)
                          .collection(widget.collectionName)
                          .orderBy('created_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: Text('No posts uploaded yet.'),
                          );
                        }

                        return GridView.builder(
                          itemCount: docs.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                          const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: Image.network(data['image_url'],
                                              fit: BoxFit.cover, width: double.infinity),
                                        ),
                                        Positioned(
                                          right: 6,
                                          top: 6,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () =>
                                                _deleteItem(doc.id, data['image_url']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      data['text'] ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  else
                    const Text('You must be signed in to view uploads.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
