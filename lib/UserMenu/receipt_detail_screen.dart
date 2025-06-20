import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class ReceiptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptDetailScreen({super.key, required this.receiptData});

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final List<Map<String, dynamic>> items = (receiptData['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final deliveryMethod = receiptData['deliveryMethod'] ?? 'Unknown';
    final paymentMethod = receiptData['paymentMethod'] ?? 'Unknown';
    final total = (receiptData['totalCharge'] ?? 0.0).toDouble();
    DateTime? timestamp;
    final rawTimestamp = receiptData['timestamp'];
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Receipt Details", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            if (timestamp != null) pw.Text("Date: ${timestamp.toLocal()}"),
            pw.Text("Delivery Method: $deliveryMethod"),
            pw.Text("Payment Method: $paymentMethod"),
            pw.SizedBox(height: 12),
            pw.Text("Items Purchased:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final name = item['medicineName'] ?? item['name'] ?? 'Unknown';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] ?? 0).toDouble();
                return pw.Text("• $name x$qty — RM ${(price * qty).toStringAsFixed(2)}");
              },
            ),
            pw.SizedBox(height: 12),
            pw.Text("Total Paid: RM ${total.toStringAsFixed(2)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = (receiptData['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final deliveryMethod = receiptData['deliveryMethod'] ?? 'Unknown';
    final paymentMethod = receiptData['paymentMethod'] ?? 'Unknown';
    final total = (receiptData['totalCharge'] ?? 0.0).toDouble();

    DateTime? timestamp;
    final rawTimestamp = receiptData['timestamp'];
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Details"), backgroundColor: Colors.lightBlueAccent),
      body: Stack(
        children: [
          // Background with translucent logo and gradient corner
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFF87CEFA)], // white to bright blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/search_care.jpeg', // ✅ make sure logo exists in assets
                width: 300,
              ),
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timestamp != null)
                  Text(
                    "Date: ${timestamp.toLocal()}".split('.')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text("Delivery Method: $deliveryMethod"),
                Text("Payment Method: $paymentMethod"),
                const SizedBox(height: 12),
                const Text("Items Purchased:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text("No items found."))
                      : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = item['medicineName'] ?? item['name'] ?? 'Unknown';
                      final qty = item['quantity'] ?? 1;
                      final price = (item['price'] ?? 0).toDouble();
                      final imageUrl = item['image_url'] ??
                          item['imageUrl'] ??
                          item['image'] ??
                          '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                            ),
                          )
                              : const Icon(Icons.medication, size: 40),
                          title: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Quantity: $qty'),
                          trailing: Text(
                            'RM ${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text("Total Paid: RM ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final pdfData = await _generatePdf();
                        await Printing.layoutPdf(onLayout: (format) async => pdfData);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Print as PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
