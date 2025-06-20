import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:search_care/UserMenu/view_healthy_tips_details.dart';

class ViewHealthyTipsPage extends StatelessWidget {
  const ViewHealthyTipsPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'title': 'Food', 'icon': Icons.fastfood, 'collection': 'food_lifestyle'},
    {'title': 'Exercise', 'icon': Icons.fitness_center, 'collection': 'exercise_lifestyle'},
    {'title': 'Healthy Facts', 'icon': Icons.health_and_safety, 'collection': 'healthyfacts_lifestyle'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Category')),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB3E5FC), Color(0xFF0288D1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Translucent center logo
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/search_care.jpeg',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Foreground content
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
                      builder: (_) => CategoryTipsPage(
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
                      Text(
                        category['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}

class CategoryTipsPage extends StatelessWidget {
  final String title;
  final String collectionName;

  const CategoryTipsPage({
    required this.title,
    required this.collectionName,
    super.key,
  });

  Future<List<Map<String, dynamic>>> _fetchTips() async {
    final admins = await FirebaseFirestore.instance.collection('admins').get();
    final List<Map<String, dynamic>> allTips = [];

    for (var admin in admins.docs) {
      final tipsSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(admin.id)
          .collection(collectionName)
          .orderBy('created_at', descending: true)
          .get();

      for (var doc in tipsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('image_url') && data.containsKey('text')) {
          allTips.add(data);
        }
      }
    }

    return allTips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title Tips')),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB3E5FC), Color(0xFF0288D1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Translucent app logo
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/search_care.jpeg',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Tips content
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No tips available yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final tips = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tips.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final tip = tips[index];

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewHealthyTipsDetailsPage(
                                    imageUrl: tip['image_url'],
                                    text: tip['text'] ?? '',
                                    title: title,
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: tip['image_url'],
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  tip['image_url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            tip['text'] ?? '',
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
          ),
        ],
      ),
    );
  }
}
