import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

/// Full-screen crop UI with a highlighted frame so the user can position the vehicle.
class VehiclePhotoCropScreen extends StatefulWidget {
  const VehiclePhotoCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List imageBytes,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => VehiclePhotoCropScreen(imageBytes: imageBytes),
      ),
    );
  }

  @override
  State<VehiclePhotoCropScreen> createState() => _VehiclePhotoCropScreenState();
}

class _VehiclePhotoCropScreenState extends State<VehiclePhotoCropScreen> {
  final _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust vehicle photo'),
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Text(
              'Drag and pinch to position your vehicle inside the frame.',
              style: context.tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Crop(
                controller: _cropController,
                image: widget.imageBytes,
                aspectRatio: 16 / 9,
                radius: AppSpacing.radiusLg,
                baseColor: cs.surface,
                maskColor: Colors.black.withValues(alpha: 0.55),
                onCropped: (result) {
                  if (!mounted) return;
                  if (result is CropSuccess) {
                    Navigator.of(context).pop(result.croppedImage);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
      ),
    );
  }
}
