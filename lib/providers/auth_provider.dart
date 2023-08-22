import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  int _kuruCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  int get kuruCount {
    return _kuruCount;
  }

  set setKuruCount(int newCount) {
    _kuruCount = newCount;
  }

  void addKuruCount() {
    _kuruCount += 1;
    if (_currentUser != null) {
      _syncKuruCountWithFirestore();
    }
  }

  User? get currentUser {
    return _currentUser;
  }

  void fetchSetCurrentUser() {
    _currentUser = _auth.currentUser;
    _syncKuruCountWithFirestore(firstTime: true);
  }

  Future<void> signInWithGoogle() async {
    UserCredential userCredential;
    if (kIsWeb) {
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Once signed in, return the UserCredential
      userCredential = await _auth.signInWithPopup(googleProvider);
      // Or use signInWithRedirect
      // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
    } else {
      // Trigger the authentication flow
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn().signIn();
      } catch (error) {
        rethrow;
      }
      if (googleUser == null) {
        return;
        // throw PlatformException(
        //   code: 'sign_in_canceled',
        //   message: 'Google Sign-In was canceled by the user.',
        // );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
    }
    if (userCredential.user != null) {
      _currentUser = userCredential.user;
      final docRef = FirebaseFirestore.instance
          .collection('userKuruCount')
          .doc(userCredential.user!.uid);
      docRef.get().then((snap) {
        if (snap.exists) {
          int onlineKuru = snap.data()!['kuruCount'];
          if (onlineKuru > _kuruCount) {
            _kuruCount = onlineKuru;
          }
        } else {
          docRef.set({
            'displayName': _currentUser!.displayName,
            'kuruCount': _kuruCount
          });
        }
        notifyListeners();
      });
    }
  }

  Future<void> _syncKuruCountWithFirestore({bool firstTime = false}) async {
    if (_currentUser != null) {
      final docRef = FirebaseFirestore.instance
          .collection('userKuruCount')
          .doc(_currentUser!.uid);
      docRef.get().then((snap) {
        if (snap.exists) {
          _kuruCount = snap.data()!['kuruCount'];
          notifyListeners();
        }
      });
      // Update the Firestore value
      if (!firstTime) {
        await docRef.update({'kuruCount': _kuruCount});
      }
    }
  }
}
