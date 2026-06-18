import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

/// 底部信息卡片：心情选择、备注输入、照片上传、位置输入
class BottomInfoCard extends StatelessWidget {
  final MoodModel? selectedMood;
  final ValueChanged<MoodModel?> onMoodChanged;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final ValueChanged<String> onNoteChanged;
  final List<String> images;
  final VoidCallback onPickImages;
  final VoidCallback? onCaptureImage;
  final ValueChanged<int> onRemoveImage;
  final String? location;
  final ValueChanged<String> onLocationChanged;
  final TextEditingController locationController;
  final VoidCallback onLocationDialog;

  const BottomInfoCard({
    super.key,
    required this.selectedMood,
    required this.onMoodChanged,
    required this.noteController,
    required this.noteFocusNode,
    required this.onNoteChanged,
    required this.images,
    required this.onPickImages,
    this.onCaptureImage,
    required this.onRemoveImage,
    required this.location,
    required this.onLocationChanged,
    required this.locationController,
    required this.onLocationDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // 1. 心情选择
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            child: Row(
              children: [
                Text(
                  '心情',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: moods.map((mood) {
                        final isSelected = selectedMood?.id == mood.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => onMoodChanged(mood),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryLight
                                    : AppTheme.bgPage,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    mood.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? AppTheme.primaryDark
                                          : AppTheme.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Divider(height: 1, thickness: 1, color: AppTheme.divider),

          // 2. 备注
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '备注',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    focusNode: noteFocusNode,
                    maxLength: 50,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '点这里补一句备注',
                      hintStyle: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(left: 8),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: onNoteChanged,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Divider(height: 1, thickness: 1, color: AppTheme.divider),

          // 3. 照片
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            child: Row(
              children: [
                Text(
                  '照片',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // 相册选择
                GestureDetector(
                  onTap: onPickImages,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo_library,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 拍照
                GestureDetector(
                  onTap: onCaptureImage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppTheme.info.withOpacity(0.3),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppTheme.info,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 照片缩略图（如果有）
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final path = images[index];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            color: AppTheme.bgSection,
                            image: path.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: GestureDetector(
                            onTap: () => onRemoveImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // 分隔线
          Divider(height: 1, thickness: 1, color: AppTheme.divider),

          // 4. 位置
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  '位置',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onLocationDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.info,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '添加位置',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 位置输入框（如果有定位）
          if (location != null && location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.bgPage,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onLocationChanged(''),
                      child: Icon(Icons.close,
                          size: 16, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
