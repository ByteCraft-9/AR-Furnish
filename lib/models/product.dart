import 'package:flutter/foundation.dart';

@immutable
class Product {
  final int id;
  final String name;
  final String description;
  final String color;
  final double price;
  final List<String> images;
  final String featureImage;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isEnabled;
  final int quantity;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.price,
    required this.images,
    required this.featureImage,
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isEnabled = true,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id']),
      name: json['name'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      price: (json['price'] as num).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      featureImage: json['feature_image'] ?? '',
      category: json['category'] ?? 'General',
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num).toInt(),
      isEnabled: json['is_enabled'] ?? true,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product(
      id: data['id'] is int ? data['id'] : int.parse(data['id']),
      name: data['name'] as String,
      description: data['description'] as String,
      color: data['color'] as String,
      price: (data['price'] as num).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      featureImage: data['feature_image'] as String,
      category: data['category'] as String,
      rating: (data['rating'] as num).toDouble(),
      reviewCount: (data['review_count'] as num).toInt(),
      isEnabled: data['is_enabled'] ?? true,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'price': price,
      'images': images,
      'featureImage': featureImage,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'is_enabled': isEnabled,
      'quantity': quantity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          color == other.color &&
          price == other.price &&
          listEquals(images, other.images) &&
          featureImage == other.featureImage &&
          category == other.category &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          isEnabled == other.isEnabled &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      color.hashCode ^
      price.hashCode ^
      images.hashCode ^
      featureImage.hashCode ^
      category.hashCode ^
      rating.hashCode ^
      reviewCount.hashCode ^
      isEnabled.hashCode ^
      quantity.hashCode;
}
