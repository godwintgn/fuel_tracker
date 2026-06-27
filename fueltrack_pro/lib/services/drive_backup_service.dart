import 'dart:async';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/google_oauth_config.dart';
import 'drive_backup_prefs.dart';

const String kDriveCanonicalBackupName = 'fueltrack_pro_current.json';

int? _driveTimeToMs(DateTime? time) => time?.toUtc().millisecondsSinceEpoch;

class DriveBackupService {
  DriveBackupService() {
    _googleSignIn = GoogleSignIn(
      scopes: const [drive.DriveApi.driveAppdataScope],
      serverClientId: kGoogleOAuthServerClientId.isEmpty
          ? null
          : kGoogleOAuthServerClientId,
    );
  }

  late final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  Future<void> signOut() => _googleSignIn.signOut();

  Future<http.Client?> _authorizedClient() => _googleSignIn.authenticatedClient();

  Future<String> ensureDeviceId(DriveBackupPrefs prefs) async {
    var id = prefs.deviceId;
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setDeviceId(id);
    }
    return id;
  }

  Future<drive.DriveApi> _api() async {
    final client = await _authorizedClient();
    if (client == null) {
      throw StateError('Not signed in to Google.');
    }
    return drive.DriveApi(client);
  }

  Future<drive.File?> findCanonicalFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$kDriveCanonicalBackupName' and trashed = false",
      $fields: 'files(id,name,modifiedTime,size)',
    );
    final files = list.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  Future<DriveUploadResult> uploadBackup({
    required Uint8List bytes,
    required DriveBackupPrefs prefs,
  }) async {
    final api = await _api();
    final existing = await findCanonicalFile(api);
    final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);

    late drive.File written;
    final existingId = existing?.id;
    if (existingId != null) {
      written = await api.files.update(
        drive.File()..name = kDriveCanonicalBackupName,
        existingId,
        uploadMedia: media,
      );
    } else {
      written = await api.files.create(
        drive.File()
          ..name = kDriveCanonicalBackupName
          ..parents = const ['appDataFolder'],
        uploadMedia: media,
      );
    }

    final remoteMs = _driveTimeToMs(written.modifiedTime) ??
        DateTime.now().millisecondsSinceEpoch;
    await prefs.recordSuccessfulUpload(
      remoteModifiedMs: remoteMs,
      fileId: written.id,
    );

    return DriveUploadResult(
      fileId: written.id ?? '',
      modifiedTimeMs: remoteMs,
    );
  }

  Future<String> downloadCanonicalJson() async {
    final api = await _api();
    final meta = await findCanonicalFile(api);
    final fileId = meta?.id;
    if (fileId == null) {
      throw StateError('No backup file found in Google Drive.');
    }
    final client = await _authorizedClient();
    if (client == null) {
      throw StateError('Not signed in to Google.');
    }
    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );
    final resp = await client.get(uri);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw StateError('Drive download failed (${resp.statusCode}).');
    }
    return String.fromCharCodes(resp.bodyBytes);
  }
}

class DriveUploadResult {
  const DriveUploadResult({
    required this.fileId,
    required this.modifiedTimeMs,
  });

  final String fileId;
  final int modifiedTimeMs;
}
