import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:ar_furnish/services/ai_design_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StableDiffusionService {
  static String _baseUrl = 'https://c436-34-80-217-46.ngrok-free.app';
  static const String _defaultBaseUrl =
      'https://c436-34-80-217-46.ngrok-free.app';

  static final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Connection': 'keep-alive',
    'Keep-Alive': 'timeout=3600',
    'ngrok-skip-browser-warning': 'true',
  };

  /// Get the current base URL
  static String get baseUrl => _baseUrl;

  /// Update the base URL
  static Future<void> updateBaseUrl(String newUrl) async {
    if (newUrl.isEmpty) {
      _baseUrl = _defaultBaseUrl;
    } else {
      // Ensure URL doesn't end with a slash
      _baseUrl = newUrl.endsWith('/')
          ? newUrl.substring(0, newUrl.length - 1)
          : newUrl;
    }

    // Save to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stable_diffusion_url', _baseUrl);

    print('Updated Stable Diffusion base URL to: $_baseUrl');
  }

  /// Load saved base URL from preferences
  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('stable_diffusion_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
        print('Loaded saved base URL: $_baseUrl');
      }
    } catch (e) {
      print('Error loading saved base URL: $e');
    }
  }

  /// Reset to default base URL
  static Future<void> resetToDefaultUrl() async {
    _baseUrl = _defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stable_diffusion_url');
    print('Reset to default base URL: $_baseUrl');
  }

  /// Performs handshake to verify backend connection
  static Future<bool> handshake() async {
    try {
      print('Initiating handshake with server...');
      print('Handshake URL: $_baseUrl/handshake');

      final response = await http
          .post(
        Uri.parse('$_baseUrl/handshake'),
        headers: _defaultHeaders,
        body: jsonEncode({'message': 'Hi'}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Handshake timed out after 30 seconds');
          throw TimeoutException('Handshake timed out');
        },
      );

      print('Handshake response status: ${response.statusCode}');
      print('Handshake response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['message'] == 'hello') {
          print('Handshake successful: Server responded with "hello"');
          return true;
        } else {
          throw Exception(
              'Handshake failed: ${data['error'] ?? 'Unexpected response'}');
        }
      } else {
        throw Exception('Handshake failed: ${response.body}');
      }
    } catch (e) {
      print('Handshake error: $e');
      throw Exception('Failed to establish connection with server: $e');
    }
  }

  /// Uploads an image and prompt for AI-generated design
  static Future<String> generateDesign({
    required File imageFile,
    required String theme,
    required String prompt,
  }) async {
    try {
      print('Starting image generation request...');
      print('Image path: ${imageFile.path}');
      print('Image exists: ${imageFile.existsSync()}');
      print('Theme: $theme');
      print('Prompt: $prompt');

      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist at ${imageFile.path}');
      }

      // Record start time to calculate processing duration
      final startTime = DateTime.now();

      // Optional: Ping server root
      try {
        final testResponse = await http.get(
          Uri.parse(_baseUrl),
          headers: {'ngrok-skip-browser-warning': 'true'},
        );
        print(
            'Server root test response: ${testResponse.statusCode} ${testResponse.body}');
      } catch (e) {
        print('Warning: Server root test failed: $e');
      }

      // Perform handshake
      await handshake();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/generate'),
      );

      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=3600',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

      request.fields.addAll({
        'theme': theme,
        'prompt': prompt,
      });

      print('Sending image generation request...');

      final streamedResponse = await request.send().timeout(
        const Duration(hours: 1),
        onTimeout: () {
          throw TimeoutException('Request timed out after 1 hour');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print(
          'Image generation response: ${response.statusCode} ${response.body}');

      // Calculate processing time
      final endTime = DateTime.now();
      final processingTimeInSeconds = endTime.difference(startTime).inSeconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['image'] != null) {
          final outputImageBase64 = data['image'];

          // Save to database
          try {
            final aiDesignService = AIDesignService();
            await aiDesignService.saveAIDesign(
              prompt: prompt,
              theme: theme,
              outputImageBase64: outputImageBase64,
              processingTimeInSeconds: processingTimeInSeconds,
            );
            print('AI design saved to database successfully');
          } catch (e) {
            print('Error saving AI design to database: $e');
            // Continue even if database save fails - don't block the user from getting their image
          }

          return outputImageBase64;
        } else {
          throw Exception(data['error'] ?? 'Failed to generate design');
        }
      } else {
        throw Exception('Failed to generate design: ${response.body}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out after 1 hour');
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    } on HttpException catch (e) {
      throw Exception('HTTP error: $e');
    } catch (e) {
      throw Exception('Error generating design: $e');
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
      // Get the user ID
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
        'generator': 'stable-diffusion',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Design saved successfully to database (Stable Diffusion)');
    } catch (e) {
      debugPrint('Error saving design to database: $e');
      rethrow;
    }
  }
}
