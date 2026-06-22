import 'package:flutter_test/flutter_test.dart';
import 'package:fueltrack_pro/services/backup_crypto.dart';

void main() {
  test('seal and open roundtrip', () async {
    const payload = '{"vehicles":[],"refuel_entries":[]}';
    const passphrase = 'test-passphrase-123';

    final sealed = await BackupCrypto.sealUtf8Payload(payload, passphrase);
    expect(sealed.startsWith('FTPBAK1'), isTrue);

    final opened = await BackupCrypto.openUtf8Payload(sealed, passphrase);
    expect(opened, payload);
  });

  test('wrong passphrase fails', () async {
    const payload = '{"ok":true}';
    final sealed = await BackupCrypto.sealUtf8Payload(payload, 'correct-passphrase');
    expect(
      () => BackupCrypto.openUtf8Payload(sealed, 'wrong-passphrase'),
      throwsA(isA<Exception>()),
    );
  });
}
