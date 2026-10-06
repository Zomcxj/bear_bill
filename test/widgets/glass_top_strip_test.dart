import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/glass_materials.dart';
import 'package:bear_bill/widgets/glass_top_strip.dart';

void main() {
  tearDown(() => GlassMaterials.setEnabled(false));

  group('glassStripOpacityFor（滚动偏移换算）', () {
    test('顶部时为 0', () {
      expect(glassStripOpacityFor(0), 0.0);
      expect(glassStripOpacityFor(-10), 0.0);
    });

    test('滚动中按比例', () {
      expect(glassStripOpacityFor(30), closeTo(0.5, 0.001));
      expect(glassStripOpacityFor(60), 1.0);
    });

    test('超过淡入距离封顶 1', () {
      expect(glassStripOpacityFor(200), 1.0);
    });
  });

  group('GlassTopStrip', () {
    testWidgets('开关关闭时不渲染', (tester) async {
      GlassMaterials.setEnabled(false);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: GlassTopStrip(title: '首页', opacity: 1)),
      ));
      expect(find.text('首页'), findsNothing);
    });

    testWidgets('开关开启时渲染标题与透明度', (tester) async {
      GlassMaterials.setEnabled(true);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: GlassTopStrip(title: '首页', opacity: 0.5)),
      ));
      expect(find.text('首页'), findsOneWidget);
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.5);
    });

    testWidgets('不拦截点击（IgnorePointer）', (tester) async {
      GlassMaterials.setEnabled(true);
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: TextButton(
                  onPressed: () => tapped = true,
                  child: const Text('under'),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GlassTopStrip(title: '首页', opacity: 1),
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('under'));
      await tester.pumpAndSettle();
      expect(tapped, true);
    });
  });
}
