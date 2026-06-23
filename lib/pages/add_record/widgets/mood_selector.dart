import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../theme/app_design_system.dart';
import '../../../providers/theme_provider.dart';

/// 心情选择器
class MoodSelector extends StatelessWidget {
  final MoodModel? selectedMood;
  final Function(MoodModel?) onSelect;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DS.base),
      child: Row(
        children: [
          Text(
            '心情：',
            style: TextStyle(
              fontSize: 13,
              color: DS.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 8),
          ...moods.map((mood) {
            final isSelected = selectedMood?.id == mood.id;
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  onSelect(null); // 取消选择
                } else {
                  onSelect(mood);
                }
              },
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? DS.surfaceContainerHigh 
                      : DS.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(
                    color: isSelected 
                        ? DS.primary 
                        : DS.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: TextStyle(fontSize: 18)),
                    if (isSelected) ...[
                      SizedBox(width: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: DS.primaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
