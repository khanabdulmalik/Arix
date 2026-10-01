import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_sodium/flutter_sodium.dart';

/// Wraps libsodium operations for X25519 key exchange and
/// XSalsa20-Poly1305 authenticated encryption.
///
/// ### Background-execution hardening
///
/// [encrypt] and [decrypt] are **synchronous** NaCl Box calls that
/// involve CPU-bound work (Curve25519 scalar multiply + XSalsa20
/// stream cipher).  For small chat payloads (< 10 KB) this completes
/// in < 1 ms on modern hardware, but for safety we provide
/// [encryptInIsolate] and [decryptInIsolate] variants that spawn
/// a short-lived isolate so the platform channel and UI thread are
/// never blocked, even when the device is under heavy mesh relay load.
class CryptoService {
  /// Generate a new X25519 keypair for key-agreement.
  /// Returns a map with `publicKey` and `secretKey` as Base64 strings.
  static Future<Map<String, String>> generateKeyPair() async {
    await Sodium.init();
    final keyPair = CryptoBox.randomKeys();
    return {
      'publicKey': base64Encode(keyPair.pk),
      'secretKey': base64Encode(keyPair.sk),
    };
  }

  // ─────────────── Synchronous (main isolate) ───────────────

  /// Encrypt [plaintext] so that only the holder of [recipientPublicKey]
  /// can decrypt it, using our [senderSecretKey].
  ///
  /// Returns a Base64-encoded blob that contains the nonce prepended to
  /// the ciphertext so the receiver can decrypt without out-of-band nonce
  /// exchange.
  static String encrypt({
    required String plaintext,
    required String recipientPublicKey,
    required String senderSecretKey,
  }) {
    final nonce = CryptoBox.randomNonce();
    final ciphertext = CryptoBox.encrypt(
      Uint8List.fromList(utf8.encode(plaintext)),
      nonce,
      base64Decode(recipientPublicKey),
      base64Decode(senderSecretKey),
    );

    // Prepend nonce to ciphertext so receiver has everything needed.
    final combined = Uint8List(nonce.length + ciphertext.length);
    combined.setAll(0, nonce);
    combined.setAll(nonce.length, ciphertext);
    return base64Encode(combined);
  }

  /// Decrypt a [ciphertextBlob] (nonce+ciphertext, Base64) that was
  /// produced by [encrypt], using the [senderPublicKey] and our
  /// [recipientSecretKey].
  static String decrypt({
    required String ciphertextBlob,
    required String senderPublicKey,
    required String recipientSecretKey,
  }) {
    final combined = base64Decode(ciphertextBlob);
    final nonceLength = CryptoBox.nonceBytes;
    final nonce = combined.sublist(0, nonceLength);
    final ciphertext = combined.sublist(nonceLength);

    final plaintext = CryptoBox.decrypt(
      Uint8List.fromList(ciphertext),
      Uint8List.fromList(nonce),
      base64Decode(senderPublicKey),
      base64Decode(recipientSecretKey),
    );
    return utf8.decode(plaintext);
  }

  // ─────────── Isolate-offloaded (background safe) ────────────

  /// Same as [encrypt] but runs the NaCl operations in a short-lived
  /// isolate so the main thread is never blocked during relay storms.
  static Future<String> encryptInIsolate({
    required String plaintext,
    required String recipientPublicKey,
    required String senderSecretKey,
  }) {
    return Isolate.run(() => encrypt(
          plaintext: plaintext,
          recipientPublicKey: recipientPublicKey,
          senderSecretKey: senderSecretKey,
        ));
  }

  /// Same as [decrypt] but runs in a short-lived isolate.
  static Future<String> decryptInIsolate({
    required String ciphertextBlob,
    required String senderPublicKey,
    required String recipientSecretKey,
  }) {
    return Isolate.run(() => decrypt(
          ciphertextBlob: ciphertextBlob,
          senderPublicKey: senderPublicKey,
          recipientSecretKey: recipientSecretKey,
        ));
  }
}
