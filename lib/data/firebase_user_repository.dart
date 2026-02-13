import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return AppUser(
        id: uid,
        email: data['email'] ?? '',
        displayName: data['displayName'],
        bio: data['bio'],
        isPublic: data['isPublic'] ?? true, // Default se manca
      );
    } catch (e) {
      throw Exception("Errore nel caricamento profilo: $e");
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? bio,
    bool? isPublic,
  }) async {
    final Map<String, dynamic> updates = {};

    if (bio != null) updates['bio'] = bio;
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (updates.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(
              updates,
              SetOptions(merge: true), // Merge per non sovrascrivere tutto
            );
      } catch (e) {
        throw Exception("Impossibile aggiornare il profilo: $e");
      }
    }
  }
}
