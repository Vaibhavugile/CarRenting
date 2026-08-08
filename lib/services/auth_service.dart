
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static final AuthService instance =
      AuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // ============================================================
  // REGISTER
  //
  // Creates:
  //
  // Firebase Authentication account
  // +
  // users/{uid}
  //
  // Business and branch are NOT created here.
  // They are created in Business Setup.
  // ============================================================

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final normalizedName =
        fullName.trim();

    final normalizedEmail =
        email.trim().toLowerCase();

    final normalizedPhone =
        phone?.trim();

    // ------------------------------------------------------------
    // Create Firebase Authentication account
    // ------------------------------------------------------------

    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message:
            'Unable to create your account.',
      );
    }

    // ------------------------------------------------------------
    // Update Firebase display name
    // ------------------------------------------------------------

    await user.updateDisplayName(
      normalizedName,
    );

    // ------------------------------------------------------------
    // Create initial user profile
    //
    // Business fields are intentionally null.
    //
    // They will be populated after Business Setup.
    // ------------------------------------------------------------

    final now = DateTime.now();

    final userModel = UserModel(
      uid: user.uid,

      fullName: normalizedName,

      email: normalizedEmail,

      phone: normalizedPhone == null ||
              normalizedPhone.isEmpty
          ? null
          : normalizedPhone,

      photoUrl: null,

      businessId: null,

      branchId: null,

      branchCode: null,

      role: 'owner',

      isActive: true,

      createdAt: now,

      updatedAt: now,
    );

    // ------------------------------------------------------------
    // Save Firestore user profile
    // ------------------------------------------------------------

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
          userModel.toFirestore(),
        );

    return userModel;
  }

  // ============================================================
  // LOGIN
  //
  // Authentication is handled by Firebase.
  //
  // Then we load the small users/{uid} profile.
  // ============================================================

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail =
        email.trim().toLowerCase();

    // ------------------------------------------------------------
    // Firebase login
    // ------------------------------------------------------------

    final credential =
        await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message:
            'Unable to sign in.',
      );
    }

    // ------------------------------------------------------------
    // Fetch only the user's small profile document.
    //
    // We DO NOT fetch businesses, branches, vehicles,
    // bookings, customers, etc. during login.
    // This keeps the initial read count low.
    // ------------------------------------------------------------

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'profile-not-found',
        message:
            'Your account profile could not be found.',
      );
    }

    final userModel =
        UserModel.fromFirestore(
      userDoc,
    );

    // ------------------------------------------------------------
    // Check whether the account is active.
    // ------------------------------------------------------------

    if (!userModel.isActive) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'account-disabled',
        message:
            'Your account has been disabled.',
      );
    }

    return userModel;
  }

  // ============================================================
  // GET USER PROFILE
  //
  // Useful when we need the current user's business context.
  // ============================================================

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return null;
    }

    return UserModel.fromFirestore(
      userDoc,
    );
  }

  // ============================================================
  // CHECK BUSINESS SETUP
  //
  // This reads ONLY users/{uid}.
  //
  // Returns true when the user has completed:
  //
  // businessId
  // branchId
  // branchCode
  // ============================================================

  Future<bool> hasBusinessSetup() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return false;
    }

    final data =
        userDoc.data();

    if (data == null) {
      return false;
    }

    final businessId =
        data['businessId'] as String?;

    final branchId =
        data['branchId'] as String?;

    final branchCode =
        data['branchCode'] as String?;

    return businessId != null &&
        businessId.isNotEmpty &&
        branchId != null &&
        branchId.isNotEmpty &&
        branchCode != null &&
        branchCode.isNotEmpty;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> sendPasswordResetEmail(
    String email,
  ) async {
    final normalizedEmail =
        email.trim().toLowerCase();

    await _auth.sendPasswordResetEmail(
      email: normalizedEmail,
    );
  }

  // ============================================================
  // DELETE AUTH ACCOUNT
  //
  // This is kept separate because account deletion should
  // eventually also handle Firestore cleanup/soft deletion.
  // ============================================================

  Future<void> deleteAuthAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message:
            'No authenticated user found.',
      );
    }

    await user.delete();
  }
}
