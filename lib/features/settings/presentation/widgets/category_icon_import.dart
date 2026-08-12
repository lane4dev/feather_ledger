import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

/// Decodes an image once so the preview and exported crop use the same pixels.
Future<ui.Image> decodeCategoryIcon(Uint8List bytes) async {
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
    throw const FormatException('Invalid image size');
  }
  final png = bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a;
  final jpeg = bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  if (!png && !jpeg) throw const FormatException('Unsupported image');
  final codec = await ui.instantiateImageCodec(bytes,
      targetWidth: 512, allowUpscaling: false);
  try {
    final image = (await codec.getNextFrame()).image;
    if (image.width < 32 || image.height < 32) {
      image.dispose();
      throw const FormatException('Image is too small');
    }
    return image;
  } finally {
    codec.dispose();
  }
}

/// Produces a small, square image that can be stored in a category event.
Future<String> encodeCategoryIcon(ui.Image image, ui.Rect source) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    source,
    const ui.Rect.fromLTWH(0, 0, 96, 96),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  try {
    final cropped = await picture.toImage(96, 96);
    try {
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const FormatException('Cannot encode image');
      return '${CategoryIcon.imagePrefix}${base64Encode(data.buffer.asUint8List())}';
    } finally {
      cropped.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Future<String> cropCategoryIcon(Uint8List bytes) async {
  final image = await decodeCategoryIcon(bytes);
  try {
    final side = image.width < image.height ? image.width : image.height;
    return await encodeCategoryIcon(
        image,
        ui.Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2,
            side.toDouble(), side.toDouble()));
  } finally {
    image.dispose();
  }
}
