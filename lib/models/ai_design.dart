import 'package:cloud_firestore/cloud_firestore.dart';

class AIDesign {
  final String id;
  final String userId;
  final String prompt;
  final String theme;
  final String outputImageUrl;
  final DateTime createdAt;
  final int processingTimeInSeconds;

  AIDesign({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.theme,
    required this.outputImageUrl,
    required this.createdAt,
    required this.processingTimeInSeconds,
  });

  // Factory constructor to create AIDesign from Firestore document
  factory AIDesign.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AIDesign(
      id: doc.id,
      userId: data['userId'] ?? '',
      prompt: data['prompt'] ?? '',
      theme: data['theme'] ?? '',
      outputImageUrl: data['outputImageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processingTimeInSeconds: data['processingTimeInSeconds'] ?? 0,
    );
  }

  // Convert AIDesign to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'theme': theme,
      'outputImageUrl': outputImageUrl,
      'createdAt': createdAt,
      'processingTimeInSeconds': processingTimeInSeconds,
    };
  }
}
