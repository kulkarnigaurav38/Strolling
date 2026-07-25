/// Fake auth for local / App Distribution builds.
///
/// Firebase is only used for App Distribution (project + `google-services.json`).
/// Real Auth / Firestore can land later without changing the welcome UI flow.
class AuthService {
  Future<bool> signInWithGoogle() => _fake('google');

  Future<bool> signInWithFacebook() => _fake('facebook');

  Future<bool> signInAnonymously() => _fake('guest');

  Future<void> signOut() async {}

  Future<bool> _fake(String provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // ignore: avoid_print
    print('Mock sign-in as $provider');
    return true;
  }
}
