import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/widgets/app_card.dart';
import 'package:bear_bill/theme/app_design_system.dart';

void main() {
  group('AppCard', () {
    testWidgets('渲染子组件', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(child: Text('测试')),
          ),
        ),
      );

      expect(find.text('测试'), findsOneWidget);
    });

    testWidgets('点击回调触发', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: Text('可点击'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('可点击'));
      expect(tapped, true);
    });

    testWidgets('自定义颜色生效', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              color: customColor,
              child: Text('红色卡片'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, customColor);
    });

    testWidgets('无边框模式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              showBorder: false,
              child: Text('无边框'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('有边框模式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              showBorder: true,
              child: Text('有边框'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('深色模式下默认颜色变化', (tester) async {
      DS.setDarkMode(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(child: Text('浅色')),
          ),
        ),
      );
      final lightContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      final lightColor =
          (lightContainer.decoration as BoxDecoration).color!;

      DS.setDarkMode(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(child: Text('深色')),
          ),
        ),
      );
      final darkContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      final darkColor =
          (darkContainer.decoration as BoxDecoration).color!;

      expect(lightColor, isNot(equals(darkColor)));

      DS.setDarkMode(false);
    });
  });
}
