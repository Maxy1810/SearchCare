import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'receipt_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("User not logged in.");
      return const Scaffold(
        body: Center(child: Text("Please log in to view order history")),
      );
    }

    final receiptRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('receipt');

    debugPrint("Fetching receipts for user: ${user.uid}");

    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: receiptRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("Waiting for receipt snapshots...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Error fetching receipts: ${snapshot.error}");
            return const Center(child: Text("Error loading order history."));
          }

          final receipts = snapshot.data?.docs ?? [];

          debugPrint("Total receipts fetched: ${receipts.length}");

          if (receipts.isEmpty) {
            debugPrint("No receipts found.");
            return const Center(child: Text("No receipts found"));
          }

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final doc = receipts[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              final total = (data['totalCharge'] ?? 0.0).toDouble();
              final deliveryMethod = data['deliveryMethod'] ?? 'Unknown';
              final paymentMethod = data['paymentMethod'] ?? 'Unknown';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text('Total: RM ${total.toStringAsFixed(2)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery: $deliveryMethod'),
                      Text('Payment: $paymentMethod'),
                      if (timestamp != null)
                        Text('Date: ${timestamp.toLocal()}'.split('.')[0]),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    debugPrint("Tapped receipt $docId");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptDetailScreen(receiptData: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
