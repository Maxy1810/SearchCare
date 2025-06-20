import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update_medicine.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewMedicinePage extends StatelessWidget {
  const ViewMedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No admin is currently logged in')),
      );
    }

    final medicineStream = FirebaseFirestore.instance
        .collection('admins')
        .doc(currentUser.uid)
        .collection('medicines')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEBDCF9), Color(0xFFFFE3C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Translucent logo at center
            Center(
              child: Opacity(
                opacity: 0.07,
                child: Image.asset(
                  'assets/images/search_care.jpeg', // Make sure this path is correct
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Main content
            StreamBuilder<QuerySnapshot>(
              stream: medicineStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No medicines found.'));
                }

                final allMeds = snapshot.data!.docs;

                final lowStock = allMeds.where((doc) => (doc['stock'] as int) <= 10).toList();
                final mediumStock = allMeds.where((doc) => (doc['stock'] as int) > 10 && (doc['stock'] as int) <= 50).toList();
                final highStock = allMeds.where((doc) => (doc['stock'] as int) > 50).toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if (lowStock.isNotEmpty) _buildSection('Low Stock (≤10)', lowStock, context),
                      if (mediumStock.isNotEmpty) _buildSection('Medium Stock (11–50)', mediumStock, context),
                      if (highStock.isNotEmpty) _buildSection('High Stock (>50)', highStock, context),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<DocumentSnapshot> medicines, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medicines.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return GestureDetector(
                onTap: () => _showMedicineDetails(context, medicine),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            medicine['image_url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(medicine['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('RM ${medicine['price']}'),
                            Text('Stock: ${medicine['stock']}'),
                            Text(
                              'Prescription: ${medicine['prescription_required'] ? 'Yes' : 'No'}',
                              style: TextStyle(
                                color: medicine['prescription_required'] ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(BuildContext context, DocumentSnapshot medicine) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(medicine['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(medicine['image_url'], height: 150),
            const SizedBox(height: 10),
            Text("Price: RM ${medicine['price']}"),
            Text("Stock: ${medicine['stock']}"),
            if (medicine['prescription_required']) ...[
              const SizedBox(height: 8),
              const Text("Prescription Required", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(medicine['prescription_details'] ?? ""),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpdateMedicinePage(medicine: medicine),
                ),
              );
            },
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Medicine'),
                  content: const Text('Are you sure you want to delete this medicine?'),
                  actions: [
                    TextButton(child: const Text('No'), onPressed: () => Navigator.pop(ctx, false)),
                    TextButton(child: const Text('Yes'), onPressed: () => Navigator.pop(ctx, true)),
                  ],
                ),
              );

              if (confirm ?? false) {
                final adminId = FirebaseAuth.instance.currentUser?.uid;
                if (adminId != null) {
                  await FirebaseFirestore.instance
                      .collection('admins')
                      .doc(adminId)
                      .collection('medicines')
                      .doc(medicine.id)
                      .delete();

                  await FirebaseFirestore.instance
                      .collection('medicines')
                      .doc(medicine.id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine deleted successfully')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
