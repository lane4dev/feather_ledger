import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:feather_ledger/features/settings/presentation/widgets/category_icon_import.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crops the center of an image into a portable square PNG', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 120, 60),
        ui.Paint()..color = const ui.Color(0xffff0000));
    canvas.drawRect(const ui.Rect.fromLTWH(30, 0, 60, 60),
        ui.Paint()..color = const ui.Color(0xff00ff00));
    final image = await recorder.endRecording().toImage(120, 60);
    final input = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    final key = await cropCategoryIcon(input);
    expect(key, startsWith(CategoryIcon.imagePrefix));
    final codec = await ui.instantiateImageCodec(
        base64Decode(key.substring(CategoryIcon.imagePrefix.length)));
    final result = (await codec.getNextFrame()).image;
    expect(result.width, 96);
    expect(result.height, 96);
    final pixels =
        (await result.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
    expect(pixels.sublist(4 * (48 * 96 + 10), 4 * (48 * 96 + 10) + 4),
        [0, 255, 0, 255]);
    result.dispose();
    codec.dispose();
  });

  test('exports the selected source region', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 120, 60),
        ui.Paint()..color = const ui.Color(0xffff0000));
    canvas.drawRect(const ui.Rect.fromLTWH(60, 0, 60, 60),
        ui.Paint()..color = const ui.Color(0xff00ff00));
    final image = await recorder.endRecording().toImage(120, 60);
    final key =
        await encodeCategoryIcon(image, const ui.Rect.fromLTWH(60, 0, 60, 60));
    final codec = await ui.instantiateImageCodec(
        base64Decode(key.substring(CategoryIcon.imagePrefix.length)));
    final cropped = (await codec.getNextFrame()).image;
    final pixels =
        (await cropped.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
    const offset = 4 * (48 * 96 + 48);
    expect(pixels.sublist(offset, offset + 4), [0, 255, 0, 255]);
    cropped.dispose();
    codec.dispose();
    image.dispose();
  });

  test('rejects unsupported image data', () async {
    await expectLater(
        cropCategoryIcon(Uint8List.fromList([1, 2, 3])), throwsFormatException);
  });
}
