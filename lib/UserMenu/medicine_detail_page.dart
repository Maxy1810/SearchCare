import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'confirm_medicine.dart'; // Updated import

class MedicineDetailPage extends StatelessWidget {
  final DocumentSnapshot medicine;
  final String adminId;

  const MedicineDetailPage({
    super.key,
    required this.medicine,
    required this.adminId,
  });

  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to cart')),
      );
      return;
    }

    final medicineData = medicine.data() as Map<String, dynamic>;
    final userCartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final cartDoc = await userCartRef.doc(medicine.id).get();
    if (cartDoc.exists) {
      final currentQty = cartDoc['quantity'] ?? 1;
      await userCartRef.doc(medicine.id).update({'quantity': currentQty + 1});
    } else {
      await userCartRef.doc(medicine.id).set({
        ...medicineData,
        'adminId': adminId,
        'medicineId': medicine.id,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = medicine.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] ?? 'Medicine Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2EBF2), Color(0xFFC8E6C9)], // Light blue & green
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Translucent center logo
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/search_care.jpeg',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (data['image_url'] != null &&
                      data['image_url'].toString().isNotEmpty)
                    Image.network(
                      data['image_url'],
                      height: 200,
                      fit: BoxFit.contain,
                    )
                  else
                    const Icon(Icons.medication, size: 100),

                  const SizedBox(height: 16),

                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text('Price: RM ${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                  Text('Stock: ${data['stock'] ?? 0}'),

                  if (data['prescription_required'] == true) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Prescription Required',
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(data['prescription_details'] ?? ''),
                  ],

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final data = medicine.data() as Map<String, dynamic>;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmMedicinePage(
                                medicineData: data,
                                adminId: adminId,
                                medicineId: medicine.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Buy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addToCart(context),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
