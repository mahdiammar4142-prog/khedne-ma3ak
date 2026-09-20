import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _guestKey = 'lebanon_places_guest';

/// Auth state: signed in (Firebase user), guest, or needs auth.
sealed class AuthState {}

class AuthSignedIn extends AuthState {
  final User user;
  AuthSignedIn(this.user);
}

class AuthGuest extends AuthState {}

class AuthNeedsLogin extends AuthState {}

/// Handles Firebase Auth and guest persistence.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    SharedPreferences? prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _prefs = prefs;

  final FirebaseAuth _auth;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Whether the user chose "Continue as guest".
  Future<bool> isGuest() async {
    final p = await prefs;
    return p.getBool(_guestKey) ?? false;
  }

  Future<void> setGuest(bool value) async {
    final p = await prefs;
    await p.setBool(_guestKey, value);
  }

  Future<void> clearGuest() async {
    await setGuest(false);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await clearGuest();
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await clearGuest();
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await clearGuest();
    await _auth.signOut();
  }
}
