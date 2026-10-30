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
        bool isAuthorized = doc['isAuthorized'] ?? true;
        
        if (!isAuthorized) {
           QuerySnapshot membersSnapshot = await _firestore.collection('members').get();
           int messMembersCount = membersSnapshot.docs
               .where((d) => (d.data() as Map<String, dynamic>?)?['role'] != 'wallet_only')
               .length;
           
           if (messMembersCount < 8) {
               await _firestore.collection('members').doc(user.email).update({
                 'isAuthorized': true,
                 'role': 'member',
               });
           } else {
               await _firestore.collection('members').doc(user.email).update({
                 'isAuthorized': true,
                 'role': 'wallet_only',
               });
           }
        }
        
        return true;
      } else {
        QuerySnapshot membersSnapshot = await _firestore.collection('members').get();
        List<DocumentSnapshot> messMembers = membersSnapshot.docs
            .where((d) => (d.data() as Map<String, dynamic>?)?['role'] != 'wallet_only')
            .toList();
        
        bool isAdmin = messMembers.isEmpty; 
        String assignedRole = 'wallet_only';

        if (isAdmin) {
          assignedRole = 'admin';
        } else if (messMembers.length < 8) {
          assignedRole = 'member';
        } else {
          assignedRole = 'wallet_only'; // 🚀 9th user onwards becomes wallet_only user!
        }

        MemberModel newMember = MemberModel(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? '',
          role: assignedRole,
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
        bool isAuthorized = doc['isAuthorized'] ?? true;
        if (!isAuthorized) {
          return await checkAndCreateUserProfile(currentUser!);
        }
        return true;
      } else {
        return await checkAndCreateUserProfile(currentUser!);
      }
    } catch (e) {
      debugPrint("Error checking current user auth: $e");
      return false;
    }
  }

  // Get current user's role ('admin', 'member', or 'wallet_only')
  Future<String> getCurrentUserRole() async {
    if (currentUser == null || currentUser!.email == null) return 'guest';
    
    try {
      DocumentSnapshot doc = await _firestore.collection('members').doc(currentUser!.email).get();
      if (doc.exists) {
        return (doc['role'] ?? 'member').toString().toLowerCase();
      }
    } catch (e) {
      debugPrint("Error getting current user role: $e");
    }
    return 'member';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
