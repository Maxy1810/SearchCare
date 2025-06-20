import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkoutcart_page.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  double calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    return cartItems.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0).toDouble();
      final quantity = (data['quantity'] ?? 1) as int;
      return sum + (price * quantity);
    });
  }

  void updateQuantity(DocumentReference docRef, int currentQty, int delta) {
    final newQty = currentQty + delta;
    if (newQty > 0) {
      docRef.update({'quantity': newQty});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view your cart')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFC1CC)], // Light pink to light red
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Translucent App Logo in Background
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/search_care.jpeg', // ✅ Make sure you have the logo here
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Foreground: Cart Content
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cartItems = snapshot.data?.docs ?? [];

                if (cartItems.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }

                final total = calculateTotal(cartItems);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final doc = cartItems[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final quantity = data['quantity'] ?? 1;
                          final price = (data['price'] ?? 0).toDouble();

                          final imageUrl = data['image'] ??
                              data['image_url'] ??
                              data['imageUrl'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: imageUrl != null &&
                                  imageUrl.toString().isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                                ),
                              )
                                  : const Icon(Icons.medication, size: 40),
                              title: Text(data['name'] ?? 'Medicine'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: () => updateQuantity(
                                            doc.reference, quantity, -1),
                                      ),
                                      Text('$quantity'),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: () => updateQuantity(
                                            doc.reference, quantity, 1),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Total: RM ${(price * quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => doc.reference.delete(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Total: RM ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutCartPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart_checkout),
                            label: const Text('Checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
