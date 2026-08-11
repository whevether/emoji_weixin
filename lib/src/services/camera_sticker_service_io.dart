import 'package:flutter/material.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../models/sticker.dart';
import '../platform/platform_caps.dart';
import 'sticker_edit_helper.dart';

Future<Sticker?> captureAndEdit(BuildContext context) async {
  if (!PlatformCaps.supportsWechatCamera) {
    // Desktop: file_picker image + editor.
    return StickerEditHelper.pickImageEditAndSave(context);
  }

  final entity = await CameraPicker.pickFromCamera(
    context,
    pickerConfig: const CameraPickerConfig(
      enableRecording: false,
      maximumRecordingDuration: null,
    ),
  );
  if (entity == null || !context.mounted) return null;

  final file = await entity.file;
  if (file == null || !context.mounted) return null;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  return StickerEditHelper.editBytesAndSave(context, bytes);
}
