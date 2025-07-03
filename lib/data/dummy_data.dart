import 'package:flutter/material.dart';

class DummyData {
  static final List<Map<String, dynamic>> products = [
    {
      'id': 1,
      'name': 'Modern Leather Sofa',
      'description':
          'Elegant 3-seater leather sofa with chrome legs and premium upholstery',
      'price': 999.99,
      'images': [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc',
        'https://images.unsplash.com/photo-1550254478-ead40cc54513',
      ],
      'category': 'Sofas',
      'specifications': {
        'material': 'Genuine Leather',
        'dimensions': '220x85x75 cm',
        'color': 'Brown',
        'weight': '45 kg',
      },
      'rating': 4.5,
      'reviewCount': 128,
    },
    {
      'id': '2',
      'name': 'Scandinavian Platform Bed',
      'description':
          'Minimalist queen size platform bed with integrated storage',
      'price': 799.99,
      'images': [
        'https://images.unsplash.com/photo-1505693314120-0d443867891c',
        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af',
      ],
      'category': 'Beds',
      'specifications': {
        'material': 'Oak Wood',
        'dimensions': '160x200 cm',
        'color': 'Natural Oak',
        'weight': '80 kg',
      },
      'rating': 4.8,
      'reviewCount': 95,
    },
    {
      'id': '3',
      'name': 'Glass Top Dining Set',
      'description': 'Contemporary 6-seater dining set with tempered glass top',
      'price': 1299.99,
      'images': [
        'https://images.unsplash.com/photo-1617104424032-b9bd6972d0e4',
        'https://images.unsplash.com/photo-1617104424032-b9bd6972d0e4',
      ],
      'category': 'Tables',
      'specifications': {
        'material': 'Glass, Metal',
        'dimensions': '180x90x75 cm',
        'color': 'Clear/Black',
        'weight': '65 kg',
      },
      'rating': 4.3,
      'reviewCount': 74,
    },
    {
      'id': '4',
      'name': 'Velvet Accent Chair',
      'description': 'Luxurious velvet armchair with gold-finished metal frame',
      'price': 449.99,
      'images': [
        'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91',
        'https://images.unsplash.com/photo-1580480055273-228ff5388ef8',
      ],
      'category': 'Chairs',
      'specifications': {
        'material': 'Velvet, Metal',
        'dimensions': '75x80x85 cm',
        'color': 'Emerald Green',
        'weight': '15 kg',
      },
      'rating': 4.6,
      'reviewCount': 52,
    },
    {
      'id': '5',
      'name': 'Marble Coffee Table',
      'description':
          'Modern coffee table with genuine marble top and brass base',
      'price': 599.99,
      'images': [
        'https://images.unsplash.com/photo-1577926866951-72d749650954',
        'https://images.unsplash.com/photo-1577926866951-72d749650954',
      ],
      'category': 'Tables',
      'specifications': {
        'material': 'Marble, Brass',
        'dimensions': '120x60x45 cm',
        'color': 'White/Gold',
        'weight': '35 kg',
      },
      'rating': 4.7,
      'reviewCount': 38,
    },
    {
      'id': '6',
      'name': 'Rattan Lounge Chair',
      'description': 'Handwoven rattan lounge chair with cushions',
      'price': 349.99,
      'images': [
        'https://images.unsplash.com/photo-1580480055273-228ff5388ef8',
        'https://images.unsplash.com/photo-1580480055273-228ff5388ef8',
      ],
      'category': 'Chairs',
      'specifications': {
        'material': 'Rattan, Cotton',
        'dimensions': '85x75x90 cm',
        'color': 'Natural/White',
        'weight': '12 kg',
      },
      'rating': 4.4,
      'reviewCount': 29,
    },
  ];

  static final List<Map<String, dynamic>> categories = [
    {
      'id': '1',
      'name': 'Sofas',
      'icon': Icons.weekend,
      'color': Color(0xFF00B894),
    },
    {
      'id': '2',
      'name': 'Beds',
      'icon': Icons.bed,
      'color': Color(0xFF6C5CE7),
    },
    {
      'id': '3',
      'name': 'Tables',
      'icon': Icons.table_restaurant,
      'color': Color(0xFFFF7675),
    },
    {
      'id': '4',
      'name': 'Chairs',
      'icon': Icons.chair,
      'color': Color(0xFFFD79A8),
    },
    {
      'id': '5',
      'name': 'Decor',
      'icon': Icons.home,
      'color': Color(0xFF81ECEC),
    },
  ];
}
