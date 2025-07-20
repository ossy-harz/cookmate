import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, displayName);

      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Error registering: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!, userCredential.user!.displayName ?? 'User');
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    final userData = {
      'uid': user.uid,
      'email': user.email!,
      'displayName': displayName,
      'photoURL': user.photoURL,
      'dietaryPreferences': <String>[],
      'allergies': <String>[],
      'healthGoals': <String, dynamic>{},
      'createdAt': Timestamp.now(),
      'lastUpdated': Timestamp.now(),
    };

    await userDoc.set(userData);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data == null) {
          print('User document exists but data is null');
          return null;
        }

        // Create a new user document if it doesn't have the expected structure
        if (!data.containsKey('dietaryPreferences') ||
            !data.containsKey('allergies') ||
            !data.containsKey('healthGoals')) {
          print('User document missing required fields, recreating...');
          await _createUserDocument(currentUser!, currentUser!.displayName ?? 'User');
          // Fetch the updated document
          final updatedDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
          if (updatedDoc.exists) {
            return UserModel.fromJson(updatedDoc.data()!);
          }
          return null;
        }

        try {
          return UserModel.fromJson(data);
        } catch (e) {
          print('Error parsing user data: $e');
          // Try to fix the document structure
          await _createUserDocument(currentUser!, currentUser!.displayName ?? 'User');
          return null;
        }
      } else {
        print('User document not found, creating...');
        await _createUserDocument(currentUser!, currentUser!.displayName ?? 'User');
        return getUserData(); // Try again after creating
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    Map<String, dynamic>? preferences,
  }) async {
    if (currentUser == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(currentUser!.uid);
      final updateData = <String, dynamic>{
        'lastUpdated': Timestamp.now(),
      };

      if (name != null) {
        updateData['displayName'] = name;
        await currentUser!.updateDisplayName(name);
      }

      if (dietaryPreferences != null) {
        updateData['dietaryPreferences'] = dietaryPreferences;
      }

      if (allergies != null) {
        updateData['allergies'] = allergies;
      }

      if (preferences != null) {
        // Update specific preference fields
        for (final entry in preferences.entries) {
          updateData[entry.key] = entry.value;
        }
      }

      await userDoc.update(updateData);

      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    if (currentUser == null) return {};

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return {
          'dietaryPreferences': data['dietaryPreferences'] ?? [],
          'allergies': data['allergies'] ?? [],
          'healthGoals': data['healthGoals'] ?? {},
        };
      }

      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }
}

