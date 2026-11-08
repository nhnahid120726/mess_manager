import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import 'notification_service.dart';

class AuthService {
  static const Set<String> _adminEmails = {
    'anondoroyn2006@gmail.com',
    'nahid3052026@gmail.com',
  };

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

  // Check if user is authorized and enforce strict 8-member limit
  Future<bool> checkAndCreateUserProfile(User user) async {
    try {
      // Save FCM Device Token for push notifications
      NotificationService().saveDeviceToken();

      final cleanEmail = (user.email ?? '').toLowerCase().trim();
      if (cleanEmail.isEmpty) return false;

      DocumentSnapshot doc = await _firestore.collection('members').doc(cleanEmail).get();

      if (doc.exists) {
        if (_adminEmails.contains(cleanEmail) && doc['role'] != 'admin') {
          await doc.reference.update({
            'role': 'admin',
            'isAuthorized': true,
          });
          return true;
        }
        // Registered existing member -> ALLOW
        bool isAuthorized = doc['isAuthorized'] ?? true;
        return isAuthorized;
      } else {
        // New user attempting to sign in
        QuerySnapshot membersSnapshot = await _firestore.collection('members').get();
        List<DocumentSnapshot> messMembers = membersSnapshot.docs
            .where((d) => (d.data() as Map<String, dynamic>?)?['role'] != 'wallet_only')
            .toList();

        // 🚀 STRICT 8-MEMBER LIMIT BLOCK
        if (messMembers.length >= 8) {
          debugPrint("Registration blocked: Mess member limit (8 members) is full.");
          return false; // Blocks Google Sign-In for 9th user!
        }

        bool isAdmin = _adminEmails.contains(cleanEmail);

        MemberModel newMember = MemberModel(
          uid: user.uid,
          name: user.displayName ?? 'ব্যবহারকারী',
          email: cleanEmail,
          role: isAdmin ? 'admin' : 'member',
          isAuthorized: true,
        );

        await _firestore.collection('members').doc(cleanEmail).set(newMember.toMap());
        return true;
      }
    } catch (e) {
      debugPrint("Error checking authorization: $e");
      return false;
    }
  }

  // Check current user role in Firestore
  Future<String> getCurrentUserRole() async {
    if (currentUser == null || currentUser!.email == null) return 'member';
    final cleanEmail = currentUser!.email!.toLowerCase().trim();

    try {
      DocumentSnapshot doc = await _firestore.collection('members').doc(cleanEmail).get();
      if (doc.exists) {
        return (doc['role'] ?? 'member').toString();
      }
      return 'member';
    } catch (e) {
      return 'member';
    }
  }

  // A standalone function to check if current logged in user is authorized
  Future<bool> isCurrentUserAuthorized() async {
    if (currentUser == null || currentUser!.email == null) return false;
    
    try {
      final cleanEmail = currentUser!.email!.toLowerCase().trim();
      DocumentSnapshot doc = await _firestore.collection('members').doc(cleanEmail).get();
      if (doc.exists) {
        if (_adminEmails.contains(cleanEmail) && doc['role'] != 'admin') {
          await doc.reference.update({
            'role': 'admin',
            'isAuthorized': true,
          });
          return true;
        }
        bool isAuthorized = doc['isAuthorized'] ?? true;
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
