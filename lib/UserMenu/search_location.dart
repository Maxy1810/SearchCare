import 'package:flutter/material.dart';

class SearchLocationPage extends StatelessWidget {
  const SearchLocationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locations = ["Kuching", "Kota Samarahan", "Serian", "Kota Padawan"];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Translucent centered logo
            Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/search_care.jpeg', // <-- Replace with your actual logo asset path
                width: 180,
              ),
            ),
            const SizedBox(height: 40),

            // Location boxes
            ...locations.map((location) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                location,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
