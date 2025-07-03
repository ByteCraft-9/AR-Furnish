import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  _PromotionsScreenState createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<String> carouselImages = [];

  @override
  void initState() {
    super.initState();
    _fetchCarouselImages();
  }

  // Fetch images from Firestore
  Future<void> _fetchCarouselImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotion') // Fixed collection name
          .get();

      final imageUrls = snapshot.docs
          .map((doc) =>
              doc['imageUrl'] as String?) // Verify field name matches Firestore
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();

      if (mounted) {
        setState(() {
          carouselImages = imageUrls;
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load promotions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
      ),
      body: carouselImages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CarouselSlider.builder(
              itemCount: carouselImages.length,
              options: CarouselOptions(
                height: 300,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                autoPlayInterval: const Duration(seconds: 3),
              ),
              itemBuilder: (context, index, realIndex) {
                final url = carouselImages[index];
                return Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: url.startsWith('http')
                      ? null
                      : const Center(child: Icon(Icons.error)),
                );
              },
            ),
    );
  }
}
