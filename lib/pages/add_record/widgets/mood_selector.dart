import 'package:flutter/material.dart';

import '../../../models/category_model.dart';
import '../../../theme/app_theme.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '心情：',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
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
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryLight 
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primary 
                        : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Text(
                        mood.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryDark,
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
