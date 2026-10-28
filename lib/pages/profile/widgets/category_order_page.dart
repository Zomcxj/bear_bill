import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../services/category_order_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../widgets/glass_sub_page_bar.dart';

/// Category order page: long-press and drag to reorder expense categories in "Add record"
///
/// The order is persisted (CategoryOrderService → SharedPreferences), and the
/// category picker, bill filters and spending map filters follow it immediately.
class CategoryOrderPage extends StatefulWidget {
  const CategoryOrderPage({super.key});

  @override
  State<CategoryOrderPage> createState() => _CategoryOrderPageState();
}

class _CategoryOrderPageState extends State<CategoryOrderPage> {
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final categories = CategoryOrderService.instance.expense;

    return Scaffold(
      backgroundColor: DS.background,
      appBar: const GlassSubPageBar(title: '分类排序'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(DS.base, DS.sm, DS.base, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: DS.onSurfaceVariant),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '长按整行即可拖动排序，记一笔的分类栏会按此展示',
                    style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.all(DS.base),
              buildDefaultDragHandles: false,
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = categories.removeAt(oldIndex);
                  categories.insert(newIndex, item);
                });
                await CategoryOrderService.instance
                    .saveOrder(categories.map((c) => c.id).toList());
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(DS.radiusMd),
                    child: child,
                  ),
                );
              },
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Container(
                  key: ValueKey(cat.id),
                  margin: EdgeInsets.only(bottom: DS.sm),
                  padding:
                      EdgeInsets.symmetric(horizontal: DS.base, vertical: 10),
                  decoration: DS.glassDecoration,
                  // Long-press the row to drag; hold the left handle to drag directly (no long press needed)
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_indicator,
                              size: 20, color: DS.onSurfaceVariant),
                         ),
                        SizedBox(width: DS.sm),
                        Text(cat.icon, style: TextStyle(fontSize: 22)),
                        SizedBox(width: DS.sm),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: DS.bodyMd.copyWith(
                              fontWeight: FontWeight.w500,
                              color: DS.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
