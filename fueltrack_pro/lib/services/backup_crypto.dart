import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart' show DartPbkdf2;

/// FuelTrack Pro `.ftbak`: PBKDF2-HMAC-SHA256 + AES-256-GCM with AAD.
abstract final class BackupCrypto {
  static const String magicFirstLine = 'FTPBAK1';
  static const String aadLabel = 'fueltrack_pro_backup_v1';

  static const int pbkdf2Iterations = 310000;
  static const int saltLength = 16;

  static final Pbkdf2 _pbkdf2 = Pbkdf2.hmacSha256(
    iterations: pbkdf2Iterations,
    bits: 256,
  );
  static final AesGcm _aes = AesGcm.with256bits();

  static List<int> get _aad => utf8.encode(aadLabel);

  /// PBKDF2-HMAC-SHA256 body matches [DartPbkdf2.deriveKey] from package:cryptography
  /// (Apache-2.0), with optional PRF-step progress for UI.
  static Future<SecretKey> _pbkdf2DeriveKeyDart({
    required DartPbkdf2 dartPbkdf2,
    required SecretKey passwordKey,
    required List<int> nonce,
    void Function(int completedPrf, int totalPrf)? onPrfProgress,
  }) async {
    final macAlgorithm = dartPbkdf2.macAlgorithm.toSync();
    final secretKeyData = await passwordKey.extract();
    final iterations = dartPbkdf2.iterations;
    final bits = dartPbkdf2.bits;
    final pauseFrequency = dartPbkdf2.pauseFrequency;
    final pausePeriod = dartPbkdf2.pausePeriod;

    final macLength = macAlgorithm.macLength;
    final numberOfBytes = (bits + 7) ~/ 8;
    final result = Uint8List(
      ((numberOfBytes + macLength - 1) ~/ macLength) * macLength,
    );

    final firstInput = Uint8List(nonce.length + 4);
    firstInput.setAll(0, nonce);

    final macState = macAlgorithm.newMacSinkSync(
      secretKeyData: secretKeyData,
      nonce: nonce,
    );

    void report(int completed) {
      onPrfProgress?.call(completed, iterations);
    }

    for (var partIndex = 0;
        partIndex < result.lengthInBytes ~/ macLength;
        partIndex++) {
      final fi = firstInput.length - 4;
      final blockIndex = partIndex + 1;
      firstInput[fi] = 0xFF & (blockIndex >> 24);
      firstInput[fi + 1] = 0xFF & (blockIndex >> 16);
      firstInput[fi + 2] = 0xFF & (blockIndex >> 8);
      firstInput[fi + 3] = 0xFF & blockIndex;

      final firstMac = macAlgorithm.calculateMacSync(
        firstInput,
        secretKeyData: secretKeyData,
        nonce: nonce,
      );
      final block = Uint8List.fromList(firstMac.bytes);
      final previous = Uint8List(block.length);
      previous.setAll(0, block);

      report(1);

      for (var step = 1; step < iterations; step++) {
        if (pauseFrequency > 100 &&
            step % pauseFrequency == 0 &&
            pausePeriod.inMicroseconds != 0) {
          await Future<void>.delayed(pausePeriod);
        }
        macState.initializeSync(
          secretKey: secretKeyData,
          nonce: nonce,
        );
        macState.addSlice(previous, 0, previous.length, true);
        final macBytes = macState.macBytes;

        for (var bi = 0; bi < block.length; bi++) {
          block[bi] ^= macBytes[bi];
        }
        for (var j = 0; j < macBytes.length; j++) {
          previous[j] = macBytes[j];
        }
        report(step + 1);
      }
      result.setAll(macLength * partIndex, block);
    }

    if (numberOfBytes == result.lengthInBytes) {
      return SecretKey(result);
    }
    return SecretKey(
      Uint8List.view(
        result.buffer,
        result.offsetInBytes,
        numberOfBytes,
      ),
    );
  }

  static Future<SecretKey> _deriveKeyFromPasswordWithProgress({
    required Pbkdf2 pbkdf2,
    required String password,
    required List<int> nonce,
    void Function(int completedPrf, int totalPrf)? onPrfProgress,
  }) async {
    return _pbkdf2DeriveKeyDart(
      dartPbkdf2: pbkdf2.toSync(),
      passwordKey: SecretKey(utf8.encode(password)),
      nonce: nonce,
      onPrfProgress: onPrfProgress,
    );
  }

  /// UTF-8 text file: magic line, JSON header line, base64(nonce||cipher||mac).
  ///
  /// [onEncryptProgress] reports 0–100 for PBKDF2, AES-GCM, and file assembly.
  static Future<String> sealUtf8Payload(
    String utf8Payload,
    String passphrase, {
    void Function(int percent)? onEncryptProgress,
  }) async {
    var lastPct = -1;
    void emit(int p) {
      final c = p.clamp(0, 100);
      if (c <= lastPct) return;
      lastPct = c;
      onEncryptProgress?.call(c);
    }

    emit(0);
    final salt = List<int>.generate(
      saltLength,
      (_) => Random.secure().nextInt(256),
    );
    emit(1);

    final secretKey = await _deriveKeyFromPasswordWithProgress(
      pbkdf2: _pbkdf2,
      password: passphrase,
      nonce: salt,
      onPrfProgress: (done, total) {
        final p = (88 * done ~/ total).clamp(0, 88);
        emit(p);
      },
    );
    emit(89);

    final nonce = _aes.newNonce();
    final plain = utf8.encode(utf8Payload);
    emit(90);
    final box = await _aes.encrypt(
      plain,
      secretKey: secretKey,
      nonce: nonce,
      aad: _aad,
    );
    emit(96);
    final concat = box.concatenation();
    final header = <String, dynamic>{
      'fileFormat': 1,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': pbkdf2Iterations,
      'bits': 256,
      'salt': base64Encode(salt),
    };
    final headerLine = jsonEncode(header);
    emit(98);
    final bodyLine = base64Encode(concat);
    emit(100);
    return '$magicFirstLine\n$headerLine\n$bodyLine';
  }

  /// Decrypts and verifies GCM tag. Throws on wrong passphrase or tampering.
  ///
  /// [onDecryptProgress] reports 0–100 for PBKDF2 and AES-GCM decrypt.
  static Future<String> openUtf8Payload(
    String fileContents,
    String passphrase, {
    void Function(int percent)? onDecryptProgress,
  }) async {
    var lastPct = -1;
    void emit(int p) {
      final c = p.clamp(0, 100);
      if (c <= lastPct) return;
      lastPct = c;
      onDecryptProgress?.call(c);
    }

    emit(0);
    final raw = fileContents.trim();
    final lines = raw.split(RegExp(r'\r?\n'));
    if (lines.length < 3) {
      throw const FormatException('Invalid backup: expected 3 lines');
    }
    if (lines[0].trim() != magicFirstLine) {
      throw const FormatException('Invalid backup: not a FuelTrack Pro .ftbak file');
    }
    final header = jsonDecode(lines[1]) as Map<String, dynamic>;
    if ((header['fileFormat'] as num?)?.toInt() != 1) {
      throw const FormatException('Unsupported backup header');
    }
    final iter = (header['iterations'] as num?)?.toInt() ?? pbkdf2Iterations;
    final bits = (header['bits'] as num?)?.toInt() ?? 256;
    final saltB64 = header['salt'] as String?;
    if (saltB64 == null) {
      throw const FormatException('Invalid backup header: missing salt');
    }
    final salt = base64Decode(saltB64);
    final cipherBytes = base64Decode(lines[2]);
    emit(2);

    final pbkdf2 = Pbkdf2.hmacSha256(iterations: iter, bits: bits);
    final secretKey = await _deriveKeyFromPasswordWithProgress(
      pbkdf2: pbkdf2,
      password: passphrase,
      nonce: salt,
      onPrfProgress: (done, total) {
        final p = (88 * done ~/ total).clamp(0, 88);
        emit(p);
      },
    );
    emit(90);

    final box = SecretBox.fromConcatenation(
      cipherBytes,
      nonceLength: _aes.nonceLength,
      macLength: _aes.macAlgorithm.macLength,
    );
    emit(92);
    final clear = await _aes.decrypt(
      box,
      secretKey: secretKey,
      aad: _aad,
    );
    emit(100);
    return utf8.decode(clear);
  }
}