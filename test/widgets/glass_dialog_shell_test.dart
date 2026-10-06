import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/glass_materials.dart';
import 'package:bear_bill/widgets/glass_dialog_shell.dart';

void main() {
  tearDown(() => GlassMaterials.setEnabled(false));

  Widget harness() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGlassConfirmDialog(
                context: context,
                title: '确认',
                message: '确定要删除吗？',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  testWidgets('关闭时回退 Material AlertDialog', (tester) async {
    GlassMaterials.setEnabled(false);
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('确定要删除吗？'), findsOneWidget);
  });

  testWidgets('开启时渲染玻璃弹窗（非 AlertDialog）', (tester) async {
    GlassMaterials.setEnabled(true);
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('确定要删除吗？'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
