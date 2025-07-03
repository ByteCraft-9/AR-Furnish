import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ar_furnish/models/ai_design.dart';

class AIDesignService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get aiDesignsCollection => _firestore.collection('AI_Model');

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Save AI design data to Firestore
  Future<AIDesign> saveAIDesign({
    required String prompt,
    required String theme,
    required String outputImageBase64,
    required int processingTimeInSeconds,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final timestamp = DateTime.now();
      
      // Create a document in Firestore
      final docRef = await aiDesignsCollection.add({
        'userId': userId,
        'prompt': prompt,
        'theme': theme,
        'outputImageUrl': outputImageBase64, // Store base64 string directly
        'createdAt': timestamp,
        'processingTimeInSeconds': processingTimeInSeconds,
      });
      
      // Get the document with its ID
      final docSnapshot = await docRef.get();
      
      // Return the AIDesign object
      return AIDesign.fromDocument(docSnapshot);
      
    } catch (e) {
      print('Error saving AI design: $e');
      throw Exception('Failed to save AI design: $e');
    }
  }

  // Get all AI designs for current user
  Stream<List<AIDesign>> getUserAIDesigns() {
    try {
      final userId = _getCurrentUserId();
      
      return aiDesignsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AIDesign.fromDocument(doc))
                .toList();
          });
    } catch (e) {
      print('Error fetching AI designs: $e');
      return Stream.value([]);
    }
  }

  // Get a single AI design by ID
  Future<AIDesign?> getAIDesignById(String designId) async {
    try {
      final docSnapshot = await aiDesignsCollection.doc(designId).get();
      
      if (docSnapshot.exists) {
        return AIDesign.fromDocument(docSnapshot);
      }
      
      return null;
    } catch (e) {
      print('Error fetching AI design: $e');
      return null;
    }
  }

  // Delete an AI design
  Future<void> deleteAIDesign(String designId) async {
    try {
      final userId = _getCurrentUserId();
      
      // First get the design to check if it belongs to the user
      final designDoc = await aiDesignsCollection.doc(designId).get();
      
      if (!designDoc.exists) {
        throw Exception('Design not found');
      }
      
      final designData = designDoc.data() as Map<String, dynamic>;
      
      // Verify the design belongs to the current user
      if (designData['userId'] != userId) {
        throw Exception('You do not have permission to delete this design');
      }
      
      // Delete the document
      await aiDesignsCollection.doc(designId).delete();
      
    } catch (e) {
      print('Error deleting AI design: $e');
      throw Exception('Failed to delete AI design: $e');
    }
  }
} 