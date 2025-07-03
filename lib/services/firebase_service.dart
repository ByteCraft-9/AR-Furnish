import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    signInOption: SignInOption.standard,
  );

  // Collections
  static final usersRef = _db.collection('users');
  static final preferencesRef = _db.collection('userPreferences');
  static final savedItemsRef = _db.collection('savedItems');
  static final userHistoryRef = _db.collection('userHistory');
  static final productsRef = _db.collection('products');
  static final ordersRef = _db.collection('orders');
  static final reviewsRef = _db.collection('reviews');
  static final categoriesRef = _db.collection('categories');
  static final promotionsRef = _db.collection('promotions');
  static final arModelsRef = _db.collection('arModels');
  static final aiDesignsRef = _db.collection('AI_Model');

  // Authentication Methods
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create initial user document
      await _createUserDocument(credential.user!);
      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) throw Exception('Google sign-in aborted');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // User Document Management
  Future<void> _createUserDocument(User user) async {
    final userDoc = await usersRef.doc(user.uid).get();

    if (!userDoc.exists) {
      await usersRef.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@')[0],
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'role': 'customer',
      });

      // Create default preferences
      await preferencesRef.doc(user.uid).set({
        'uid': user.uid,
        'theme': 'light',
        'notifications': true,
        'language': 'en',
        'units': 'metric',
      });
    } else {
      await usersRef.doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'invalid-credential':
          return 'The credential is malformed or expired.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> updateUserProfile({
    required String displayName,
    required String email,
    String? password,
  }) async {
    try {
      final user = _auth.currentUser!;

      // Update Firestore
      await usersRef.doc(user.uid).update({
        'displayName': displayName,
        'email': email,
      });

      // Update Auth
      await user.updateDisplayName(displayName);
      await user.updateEmail(email);

      if (password != null && password.isNotEmpty) {
        await user.updatePassword(password);
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get a list of AI Designs for the current user
  static Stream<QuerySnapshot> getUserAIDesigns() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    return aiDesignsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
