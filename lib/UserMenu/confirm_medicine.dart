import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'receipt_summary.dart';

class ConfirmMedicinePage extends StatefulWidget {
  final Map<String, dynamic> medicineData;
  final String adminId;
  final String medicineId;

  const ConfirmMedicinePage({
    super.key,
    required this.medicineData,
    required this.adminId,
    required this.medicineId,
  });

  @override
  State<ConfirmMedicinePage> createState() => _ConfirmMedicinePageState();
}

class _ConfirmMedicinePageState extends State<ConfirmMedicinePage> {
  String paymentMethod = 'Cash';
  String deliveryMethod = 'Take Away';
  bool isLoading = false;
  int quantity = 1;

  double get totalPrice {
    double pricePerUnit = (widget.medicineData['price'] ?? 0.0).toDouble();
    double base = pricePerUnit * quantity;
    return deliveryMethod == 'Cash on Delivery' ? base + 5.0 : base;
  }

  Future<void> _confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = user.uid;

      final medicineRef = firestore.collection('medicines').doc(widget.medicineId);
      final adminMedicineRef = firestore
          .collection('admins')
          .doc(widget.adminId)
          .collection('medicines')
          .doc(widget.medicineId);

      final medicineSnap = await medicineRef.get();
      int currentStock = (medicineSnap.data()?['stock'] ?? 0) as int;

      if (currentStock < quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock. Only $currentStock left.')),
        );
        setState(() => isLoading = false);
        return;
      }

      // 1. Create delivery document
      final deliveryRef = firestore
          .collection('users')
          .doc(uid)
          .collection('delivery')
          .doc();

      final deliveryId = deliveryRef.id;

      final deliveryData = {
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'deliveryFee': deliveryMethod == 'Cash on Delivery' ? 5.0 : 0.0,
        'totalCharge': totalPrice,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await deliveryRef.set(deliveryData);

      // 2. Add order under delivery/orders
      final orderRef = deliveryRef.collection('orders').doc();
      final orderData = {
        'medicineId': widget.medicineId,
        'name': widget.medicineData['name'],
        'price': widget.medicineData['price'],
        'quantity': quantity,
        'adminId': widget.adminId,
        'image_url': widget.medicineData['image_url'] ?? '',
      };
      await orderRef.set(orderData);

      // 3. Save receipt
      await firestore
          .collection('users')
          .doc(uid)
          .collection('receipt')
          .doc(deliveryId)
          .set({
        ...deliveryData,
        'items': [orderData],
      });

      // 4. Update stock
      await medicineRef.update({
        'stock': currentStock - quantity,
      });

      final adminSnap = await adminMedicineRef.get();
      if (adminSnap.exists) {
        int adminStock = (adminSnap.data()?['stock'] ?? 0) as int;
        await adminMedicineRef.update({
          'stock': adminStock - quantity,
        });
      }

      if (!mounted) return;

      // 5. Navigate to receipt summary
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptSummaryPage(
            deliveryId: deliveryId,
            medicineName: widget.medicineData['name'] ?? '',
            totalCharge: totalPrice,
            deliveryMethod: deliveryMethod,
            paymentMethod: paymentMethod,
          ),

        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.medicineData;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medicine['name'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Unit Price: RM ${medicine['price'].toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Quantity:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: quantity,
                  items: List.generate(10, (index) => index + 1)
                      .map((qty) => DropdownMenuItem(
                    value: qty,
                    child: Text(qty.toString()),
                  ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => quantity = val);
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            const Text('Select Payment Method'),
            DropdownButton<String>(
              value: paymentMethod,
              items: ['Cash', 'FPX Banking', 'Credit Card']
                  .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => paymentMethod = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Select Delivery Method'),
            DropdownButton<String>(
              value: deliveryMethod,
              items: ['Take Away', 'Cash on Delivery']
                  .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => deliveryMethod = value);
                }
              },
            ),
            const Spacer(),
            Text('Delivery Fee: RM ${deliveryMethod == 'Cash on Delivery' ? '5.00' : '0.00'}'),
            Text(
              'Total Charge: RM ${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmOrder,
                child: const Text('Confirm Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
