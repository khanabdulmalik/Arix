import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';

/// Manages identity keypair lifecycle: generation, secure persistence,
/// and retrieval from the platform keystore (iOS Keychain / Android
/// EncryptedSharedPreferences).
class KeyManager {
  static const _publicKeyKey = 'arix_public_key';
  static const _secretKeyKey = 'arix_secret_key';

  final FlutterSecureStorage _storage;

  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Returns `true` if a keypair already exists in the secure store.
  Future<bool> hasKeyPair() async {
    final pk = await _storage.read(key: _publicKeyKey);
    return pk != null;
  }

  /// Generates a new keypair via [CryptoService] and writes both keys
  /// into the platform secure storage.  This is a no-op if a keypair
  /// already exists.
  Future<void> ensureKeyPairExists() async {
    if (await hasKeyPair()) return;

    final keys = await CryptoService.generateKeyPair();
    await _storage.write(key: _publicKeyKey, value: keys['publicKey']!);
    await _storage.write(key: _secretKeyKey, value: keys['secretKey']!);
  }

  /// Retrieve the local public key (Base64).
  Future<String> getPublicKey() async {
    final key = await _storage.read(key: _publicKeyKey);
    if (key == null) throw StateError('Keypair has not been generated yet.');
    return key;
  }

  /// Retrieve the local secret key (Base64).
  Future<String> getSecretKey() async {
    final key = await _storage.read(key: _secretKeyKey);
    if (key == null) throw StateError('Keypair has not been generated yet.');
    return key;
  }
}
