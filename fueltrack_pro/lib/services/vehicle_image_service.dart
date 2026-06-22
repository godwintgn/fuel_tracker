import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores vehicle photos under app documents/vehicle_photos/.
abstract final class VehicleImageService {
  static Future<String> photosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'vehicle_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> saveVehiclePhoto({
    required int vehicleId,
    required List<int> bytes,
  }) async {
    final dir = await photosDir();
    final file = File(p.join(dir, 'vehicle_$vehicleId.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
