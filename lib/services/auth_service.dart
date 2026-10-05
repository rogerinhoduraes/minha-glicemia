import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    return result.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    return result.user;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<User?> signInWithGoogle() async {
    final account = await GoogleSignIn().signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<(OAuthCredential, String)?> _appleCredential() async {
    final rand = Random.secure();
    final nonce = base64UrlEncode(List.generate(32, (_) => rand.nextInt(256)));
    final hash = sha256.convert(utf8.encode(nonce)).toString();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hash,
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: nonce,
        accessToken: apple.authorizationCode,
      );
      return (credential, apple.authorizationCode);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    final apple = await _appleCredential();
    if (apple == null) return null;
    final result = await _auth.signInWithCredential(apple.$1);
    return result.user;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Reautentica (Apple), apaga os dados via [apagarDados], revoga o token da
  /// Apple e exclui o usuário. Retorna false se o usuário cancelou a reautenticação.
  /// Pode lançar [FirebaseAuthException] com code `requires-recent-login`.
  Future<bool> deleteAccount(Future<void> Function() apagarDados) async {
    final user = _auth.currentUser!;
    String? appleCode;
    if (user.providerData.any((p) => p.providerId == 'apple.com')) {
      final apple = await _appleCredential();
      if (apple == null) return false;
      await user.reauthenticateWithCredential(apple.$1);
      appleCode = apple.$2;
    }
    await apagarDados();
    if (appleCode != null) {
      await _auth.revokeTokenWithAuthorizationCode(appleCode);
    }
    await user.delete();
    await GoogleSignIn().signOut();
    return true;
  }
}
