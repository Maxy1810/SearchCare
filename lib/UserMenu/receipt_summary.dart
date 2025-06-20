import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReceiptSummaryPage extends StatelessWidget {
  final String deliveryId;

  const ReceiptSummaryPage({
    super.key,
    required this.deliveryId, required String medicineName, required double totalCharge, required String deliveryMethod, required String paymentMethod,
  });

  Future<Map<String, dynamic>> fetchDeliveryData(String uid) async {
    // Get the delivery document (metadata)
    final deliveryDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('delivery')
        .doc(deliveryId)
        .get();

    // Get the orders under that delivery
    final ordersSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('delivery')
        .doc(deliveryId)
        .collection('orders')
        .get();

    final deliveryData = deliveryDoc.data() ?? {};
    final items = ordersSnap.docs.map((doc) => doc.data()).toList();

    return {
      'delivery': deliveryData,
      'items': items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Summary")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDeliveryData(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final delivery = snapshot.data!['delivery'] ?? {};
          final List items = snapshot.data!['items'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Order:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Show ordered items
                Expanded(
                  child: items.isNotEmpty
                      ? ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final double itemTotal =
                          (item['price'] ?? 0).toDouble() * (item['quantity'] ?? 1).toDouble();

                      final imageUrl = item['image'] ??
                          item['image_url'] ??
                          '';

                      return ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.medication),
                        title: Text(item['name'] ?? 'Unknown'),
                        subtitle: Text('Quantity: ${item['quantity'] ?? 1}'),
                        trailing: Text('RM ${itemTotal.toStringAsFixed(2)}'),
                      );
                    },
                  )
                      : const Text("No order items found."),
                ),

                const Divider(),
                Text('Delivery Method: ${delivery['deliveryMethod'] ?? '-'}'),
                Text('Payment Method: ${delivery['paymentMethod'] ?? '-'}'),
                Text(
                    'Delivery Fee: RM ${delivery['deliveryFee'] != null ? delivery['deliveryFee'].toStringAsFixed(2) : '0.00'}'),
                Text(
                  'Total Charge: RM ${delivery['totalCharge'] != null ? delivery['totalCharge'].toStringAsFixed(2) : '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
