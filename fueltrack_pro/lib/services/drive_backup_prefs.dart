import 'package:shared_preferences/shared_preferences.dart';

/// Local metadata for Google Drive backup (not secrets).
class DriveBackupPrefs {
  DriveBackupPrefs._(this._p);

  final SharedPreferences _p;

  static const _kEnabled = 'drive_backup_enabled';
  static const _kFileId = 'drive_backup_canonical_file_id';
  static const _kLastUploadMs = 'drive_backup_last_upload_ms';
  static const _kLastRemoteModifiedMs = 'drive_backup_last_remote_modified_ms';
  static const _kDeviceId = 'drive_backup_device_id';
  static const _kLastError = 'drive_backup_last_error';

  static Future<DriveBackupPrefs> open() async {
    final p = await SharedPreferences.getInstance();
    return DriveBackupPrefs._(p);
  }

  bool get driveBackupEnabled => _p.getBool(_kEnabled) ?? false;

  Future<bool> setDriveBackupEnabled(bool value) => _p.setBool(_kEnabled, value);

  String? get canonicalFileId => _p.getString(_kFileId);

  int get lastSuccessfulUploadMs => _p.getInt(_kLastUploadMs) ?? 0;

  int get lastKnownRemoteModifiedMs => _p.getInt(_kLastRemoteModifiedMs) ?? 0;

  String? get deviceId => _p.getString(_kDeviceId);

  String? get lastError => _p.getString(_kLastError);

  Future<void> setDeviceId(String? value) async {
    if (value == null || value.isEmpty) {
      await _p.remove(_kDeviceId);
    } else {
      await _p.setString(_kDeviceId, value);
    }
  }

  Future<void> setLastError(String? value) async {
    if (value == null || value.isEmpty) {
      await _p.remove(_kLastError);
    } else {
      await _p.setString(_kLastError, value);
    }
  }

  Future<void> recordSuccessfulUpload({
    required int remoteModifiedMs,
    String? fileId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _p.setInt(_kLastUploadMs, now);
    await _p.setInt(_kLastRemoteModifiedMs, remoteModifiedMs);
    if (fileId != null && fileId.isNotEmpty) {
      await _p.setString(_kFileId, fileId);
    }
    await _p.remove(_kLastError);
  }
}
