import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '666532902328-b51ki1rccuf3v5gcte6eija7shdhlram.apps.googleusercontent.com',
  );
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  // Check if user is authorized and create profile if needed
  Future<bool> checkAndCreateUserProfile(User user) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('members').doc(user.email).get();

      if (doc.exists) {
        // User exists in our database, check if authorized
        bool isAuthorized = doc['isAuthorized'] ?? false;
        
        if (!isAuthorized) {
           QuerySnapshot membersCount = await _firestore.collection('members').get();
           if (membersCount.docs.length <= 8) {
               await _firestore.collection('members').doc(user.email).update({'isAuthorized': true});
               return true;
           }
        }
        
        return isAuthorized;
      } else {
        QuerySnapshot membersCount = await _firestore.collection('members').get();
        bool isAdmin = membersCount.docs.isEmpty; 
        
        if (membersCount.docs.length >= 8) {
          debugPrint("Registration full. Maximum 8 members allowed.");
          return false;
        }

        MemberModel newMember = MemberModel(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? '',
          role: isAdmin ? 'admin' : 'member',
          isAuthorized: true,
        );

        await _firestore.collection('members').doc(user.email).set(newMember.toMap());
        return true;
      }
    } catch (e) {
      debugPrint("Error checking authorization: $e");
      return false;
    }
  }

  // Check if current logged in user is authorized
  Future<bool> isCurrentUserAuthorized() async {
    if (currentUser == null || currentUser!.email == null) return false;
    
    try {
      DocumentSnapshot doc = await _firestore.collection('members').doc(currentUser!.email).get();
      if (doc.exists) {
        bool isAuthorized = doc['isAuthorized'] ?? false;
        return isAuthorized;
      } else {
         return await checkAndCreateUserProfile(currentUser!);
      }
    } catch (e) {
      debugPrint("Error checking current user auth: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
