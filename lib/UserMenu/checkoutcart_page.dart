import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'receipt_summary.dart';

class CheckoutCartPage extends StatefulWidget {
  const CheckoutCartPage({super.key});

  @override
  State<CheckoutCartPage> createState() => _CheckoutCartPageState();
}

class _CheckoutCartPageState extends State<CheckoutCartPage> {
  String paymentMethod = 'Cash';
  String deliveryMethod = 'Take Away';
  bool isLoading = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Order')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final cartDocs = snapshot.data!.docs;

            if (cartDocs.isEmpty) {
              return const Center(child: Text('Your cart is empty.'));
            }

            final cartItems = cartDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();

            final subtotal = cartItems.fold<double>(0, (sum, item) {
              final price = (item['price'] ?? 0).toDouble();
              final qty = (item['quantity'] ?? 1) as int;
              return sum + price * qty;
            });

            final deliveryFee = deliveryMethod == 'Cash on Delivery' ? 5.0 : 0.0;
            final total = subtotal + deliveryFee;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Items in Cart:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: item['image_url'] != null
                            ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.medication),
                        title: Text(item['name'] ?? 'Unknown'),
                        subtitle: Text("Qty: ${item['quantity']}"),
                        trailing: Text("RM ${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Select Payment Method"),
                DropdownButton<String>(
                  value: paymentMethod,
                  items: ['Cash', 'FPX Banking', 'Credit Card']
                      .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                      .toList(),
                  onChanged: (val) => setState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 8),
                const Text("Select Delivery Method"),
                DropdownButton<String>(
                  value: deliveryMethod,
                  items: ['Take Away', 'Cash on Delivery']
                      .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                      .toList(),
                  onChanged: (val) => setState(() => deliveryMethod = val!),
                ),
                const SizedBox(height: 16),
                Text("Subtotal: RM ${subtotal.toStringAsFixed(2)}"),
                Text("Delivery Fee: RM ${deliveryFee.toStringAsFixed(2)}"),
                Text("Total: RM ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _processCheckout(cartDocs, cartItems, total, deliveryFee),
                    child: const Text("Confirm Order"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _processCheckout(
      List<QueryDocumentSnapshot> cartDocs,
      List<Map<String, dynamic>> cartItems,
      double total,
      double deliveryFee) async {
    if (user == null) return;
    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = user!.uid;

      // Create delivery group with generated deliveryId
      final deliveryDocRef = firestore.collection('users').doc(uid).collection('delivery').doc();
      final deliveryId = deliveryDocRef.id;
      final ordersRef = deliveryDocRef.collection('orders');

      // ✅ Save delivery metadata directly to the delivery document
      await deliveryDocRef.set({
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'deliveryFee': deliveryFee,
        'totalCharge': total,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Process each cart item
      for (int i = 0; i < cartDocs.length; i++) {
        final doc = cartDocs[i];
        final item = cartItems[i];

        final medicineId = item['medicineId'];
        final adminId = item['adminId'];
        final qty = item['quantity'];

        final globalMedRef = firestore.collection('medicines').doc(medicineId);
        final adminMedRef = firestore.collection('admins').doc(adminId).collection('medicines').doc(medicineId);

        // Stock check
        final globalSnap = await globalMedRef.get();
        final currentStock = (globalSnap.data()?['stock'] ?? 0) as int;
        if (currentStock < qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not enough stock for ${item['name']}')),
          );
          setState(() => isLoading = false);
          return;
        }

        // Create individual order
        final orderData = {
          ...item,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await ordersRef.add(orderData);

        // Update stock
        await globalMedRef.update({'stock': currentStock - qty});
        final adminSnap = await adminMedRef.get();
        if (adminSnap.exists) {
          final adminStock = (adminSnap.data()?['stock'] ?? 0) as int;
          await adminMedRef.update({'stock': adminStock - qty});
        }
      }

      // Save receipt summary separately if needed (optional)
      await firestore.collection('users').doc(uid).collection('receipt').doc(deliveryId).set({
        'items': cartItems,
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'deliveryFee': deliveryFee,
        'totalCharge': total,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear cart
      for (final doc in cartDocs) {
        await doc.reference.delete();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptSummaryPage(
            medicineName: 'Multiple Items',
            totalCharge: total,
            deliveryMethod: deliveryMethod,
            paymentMethod: paymentMethod,
            deliveryId: deliveryId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checkout failed: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }
}
