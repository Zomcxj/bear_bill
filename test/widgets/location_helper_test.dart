import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/pages/add_record/widgets/location_helper.dart';

/// 测试宿主页面，挂载 LocationHelper
class _HostPage extends StatefulWidget {
  const _HostPage();

  @override
  State<_HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<_HostPage> with LocationHelper {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('手动输入路径能正确返回结果（竞态回归测试）', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _HostPage())),
    );
    final state = tester.state<_HostPageState>(find.byType(_HostPage));

    final future = state.showLocationDialog();
    await tester.pumpAndSettle(); // 选择对话框打开

    await tester.tap(find.text('手动输入'));
    await tester.pumpAndSettle(); // 手动输入对话框打开

    await tester.enterText(find.byType(TextField), '公司楼下');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isNotNull, reason: '对话框竞态导致结果丢失');
    expect(result!.name, '公司楼下');
  });

  testWidgets('取消选择返回 null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _HostPage())),
    );
    final state = tester.state<_HostPageState>(find.byType(_HostPage));

    final future = state.showLocationDialog();
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(await future, isNull);
  });
}
