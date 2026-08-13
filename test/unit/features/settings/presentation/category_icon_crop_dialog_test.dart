import 'dart:ui' as ui;

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/category_icon_crop_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dragging and zooming change the crop returned on save',
      (tester) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 200, 100),
        Paint()..color = const Color(0xff00ff00));
    final image = await recorder.endRecording().toImage(200, 100);
    Rect? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () async => result = await showDialog<Rect>(
                    context: context,
                    builder: (_) => CategoryIconCropDialog(image: image)),
                child: const Text('Open'),
              )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final viewport = find.byKey(const ValueKey('category-icon-crop-viewport'));
    await tester.timedDrag(
        viewport, const Offset(-40, 0), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(2);
    await tester.pumpAndSettle();
    final middle = tester.getCenter(viewport);
    final first =
        await tester.startGesture(middle + const Offset(-30, 0), pointer: 1);
    final second =
        await tester.startGesture(middle + const Offset(30, 0), pointer: 2);
    await first.moveBy(const Offset(-30, 0));
    await second.moveBy(const Offset(30, 0));
    await tester.pump();
    await first.moveBy(const Offset(-25, 0));
    await second.moveBy(const Offset(25, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.width, lessThan(50));
    expect(result!.center.dx, greaterThan(100));
    expect(result!.center.dy, closeTo(50, 0.01));
    image.dispose();
  });

  testWidgets('cancel does not return a crop', (tester) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint());
    final image = await recorder.endRecording().toImage(64, 64);
    var returned = false;
    Rect? result = Rect.zero;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<Rect>(
                      context: context,
                      builder: (_) => CategoryIconCropDialog(image: image));
                  returned = true;
                },
                child: const Text('Open'),
              )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(result, isNull);
    image.dispose();
  });
}
