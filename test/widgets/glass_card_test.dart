import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/widgets/glass_card.dart';
import 'package:bear_bill/theme/app_design_system.dart';

void main() {
  group('GlassCard', () {
    testWidgets('渲染子组件', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('测试文本'),
            ),
          ),
        ),
      );

      expect(find.text('测试文本'), findsOneWidget);
    });

    testWidgets('点击回调触发', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: Text('可点击'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('可点击'));
      expect(tapped, true);
    });

    testWidgets('无 onTap 时不崩溃', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('不可点击'),
            ),
          ),
        ),
      );

      expect(find.text('不可点击'), findsOneWidget);
    });

    testWidgets('自定义 padding 生效', (tester) async {
      const customPadding = EdgeInsets.all(32);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              padding: customPadding,
              child: Text('自定义内边距'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.padding, customPadding);
    });

    testWidgets('深色模式下背景透明度降低', (tester) async {
      // 浅色模式
      DS.setDarkMode(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(opacity: 0.7, child: Text('浅色')),
          ),
        ),
      );
      final lightContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(Container),
        ),
      );
      final lightDecoration = lightContainer.decoration as BoxDecoration;
      final lightColor = lightDecoration.color!;

      // 深色模式
      DS.setDarkMode(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(opacity: 0.7, child: Text('深色')),
          ),
        ),
      );
      final darkContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.byType(Container),
        ),
      );
      final darkDecoration = darkContainer.decoration as BoxDecoration;
      final darkColor = darkDecoration.color!;

      // 深色模式透明度应该更低
      expect(darkColor.opacity, lessThan(lightColor.opacity));

      // 清理
      DS.setDarkMode(false);
    });
  });
}
