import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import 'logging_service.dart';

class AuthService {
  // Singleton pattern to prevent re-initializing Google Sign-In on every UI rebuild
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '710399343176-fdoaev51g057t4p8ko7hk6jpsh2ag9vb.apps.googleusercontent.com',
  );

  // Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is admin (Backend-driven)
  Stream<bool> get isAdminStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] == 'admin');
  }

  Future<bool> checkIsAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, capture the credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Upsert the user into the global users collection
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'Unknown Player',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // AUDIT LOG
        LoggingService().logAction(AuditLogAction.userLogin, {
          'method': 'Google',
        });
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    // Log before signing out so we have user context
    await LoggingService().logAction(AuditLogAction.userLogout, {});
    
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
