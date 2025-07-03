import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplicateService {
  static const String baseUrl = 'https://api.replicate.com/v1';
  // API key is hardcoded, no need for user input
  static const String apiKey =
      'Your_Replicate_API_Key_Here'; // Replace with your actual API key
  static const String defaultModel =
      'stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478';

  // Generate interior design using Replicate API
  static Future<String> generateDesign({
    required File imageFile,
    required String theme,
    required String prompt,
    String model = defaultModel,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create the full prompt with theme
      final fullPrompt = '$theme style interior design. $prompt';

      // First, start a prediction
      final predictionResponse = await http.post(
        Uri.parse('$baseUrl/predictions'),
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': model,
          'input': {
            'prompt': fullPrompt,
            'image': 'data:image/jpeg;base64,$base64Image',
            'num_outputs': 1,
          },
        }),
      );

      if (predictionResponse.statusCode != 201) {
        throw Exception(
            'Failed to start prediction: ${predictionResponse.body}');
      }

      final predictionData = jsonDecode(predictionResponse.body);
      final String predictionId = predictionData['id'];

      debugPrint('Started Replicate prediction with ID: $predictionId');

      // Poll for the prediction result
      String status = 'starting';
      Map<String, dynamic> resultData = {};

      while (status != 'succeeded' && status != 'failed') {
        await Future.delayed(const Duration(seconds: 2));

        final statusResponse = await http.get(
          Uri.parse('$baseUrl/predictions/$predictionId'),
          headers: {
            'Authorization': 'Token $apiKey',
            'Content-Type': 'application/json',
          },
        );

        if (statusResponse.statusCode != 200) {
          throw Exception(
              'Failed to check prediction status: ${statusResponse.body}');
        }

        resultData = jsonDecode(statusResponse.body);
        status = resultData['status'];
        debugPrint('Replicate prediction status: $status');

        if (status == 'failed') {
          throw Exception('Prediction failed: ${resultData['error']}');
        }
      }

      // Get the generated image
      final output = resultData['output'];
      if (output == null || output.isEmpty) {
        throw Exception('No output generated');
      }

      // Download the image and convert to base64
      final imageUrl = output[0];
      debugPrint('Downloading generated image from: $imageUrl');
      final imageResponse = await http.get(Uri.parse(imageUrl));

      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download generated image');
      }

      return base64Encode(imageResponse.bodyBytes);
    } catch (e) {
      debugPrint('Error generating design with Replicate: $e');
      rethrow;
    }
  }

  // Save the generated design to the database
  static Future<void> saveDesign({
    required String base64Image,
    required String theme,
    required String prompt,
    required String originalImagePath,
  }) async {
    try {
      // Get the user ID (assuming Firebase Auth is used)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Reference to Firestore
      final designsCollection =
          FirebaseFirestore.instance.collection('designs');

      // Save the design
      await designsCollection.add({
        'userId': user.uid,
        'image': base64Image,
        'theme': theme,
        'prompt': prompt,
        'originalImagePath': originalImagePath,
        'generator': 'replicate',
        'model': defaultModel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Design saved successfully to database');
    } catch (e) {
      debugPrint('Error saving design to database: $e');
      rethrow;
    }
  }
}
