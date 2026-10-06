import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/widgets/tab_swipe.dart';

void main() {
  group('barTabFromX（底栏按住滑动换算）', () {
    test('5 等分均分到各 Tab', () {
      expect(barTabFromX(40, 400, 5), 0); // [0, 80) → 0
      expect(barTabFromX(90, 400, 5), 1); // [80, 160) → 1
      expect(barTabFromX(300, 400, 5), 3); // [240, 320) → 3
      expect(barTabFromX(390, 400, 5), 4); // [320, 400) → 4
    });

    test('越界指针收敛到两端', () {
      expect(barTabFromX(-10, 400, 5), 0);
      expect(barTabFromX(410, 400, 5), 4);
    });

    test('非法宽度/单 Tab 安全兜底', () {
      expect(barTabFromX(100, 0, 5), 0);
      expect(barTabFromX(100, 400, 1), 0);
    });
  });

  group('底栏按住滑动（自研交互，关闭玻璃时使用）', () {
    Widget harness({
      required ValueChanged<int> onSwitchTo,
      required ValueChanged<int> onTap,
    }) {
      var current = 0;
      return StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: Builder(
              builder: (barContext) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) {
                  final box = barContext.findRenderObject() as RenderBox;
                  final idx = barTabFromX(d.localPosition.dx, box.size.width, 5);
                  if (idx != current) {
                    setState(() => current = idx);
                    onSwitchTo(idx);
                  }
                },
                child: Container(
                  height: 64,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => onTap(current),
                    child: Text('bar tab $current'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('按住底栏从第 1 格拖到第 3 格 → 依次切到 1、2', (tester) async {
      final switched = <int>[];
      await tester.pumpWidget(harness(
        onSwitchTo: switched.add,
        onTap: (_) {},
      ));

      // 默认测试窗 800x600，底栏高 64 → y ≈ 568；起点 x=80（第 1 格中心）
      final gesture = await tester.startGesture(const Offset(80, 568));
      // moveBy 一次只产生一个采样点，需分步经过第 2 格再进第 3 格
      await gesture.moveBy(const Offset(160, 0)); // x=240 → 第 2 格
      await tester.pump();
      await gesture.moveBy(const Offset(160, 0)); // x=400 → 第 3 格
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(switched, [1, 2]);
    });

    testWidgets('点按底栏项仍触发点击，不误触切换', (tester) async {
      final switched = <int>[];
      var taps = 0;
      await tester.pumpWidget(harness(
        onSwitchTo: switched.add,
        onTap: (_) => taps++,
      ));

      await tester.tap(find.text('bar tab 0'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(switched, isEmpty);
    });
  });
}
