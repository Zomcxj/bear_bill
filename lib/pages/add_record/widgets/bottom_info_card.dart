import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_design_system.dart';

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
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(color: DS.outlineVariant),
      ),
      child: Column(
        children: [
          // 1. 心情选择
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DS.base,
              vertical: 10,
            ),
            child: Row(
              children: [
                Text(
                  '心情',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: moods.map((mood) {
                        final isSelected = selectedMood?.id == mood.id;
                        return Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => onMoodChanged(mood),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DS.surfaceContainerHigh
                                    : DS.background,
                                borderRadius:
                                    BorderRadius.circular(DS.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? DS.primary
                                      : DS.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.emoji,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    mood.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? DS.primaryContainer
                                          : DS.onSurfaceVariant,
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
          Divider(height: 1, thickness: 1, color: DS.outlineVariant),

          // 2. 备注
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DS.base,
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
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 12),
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
                        color: DS.outline,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(left: 8),
                      counterText: '',
                    ),
                    style: TextStyle(fontSize: 14),
                    onChanged: onNoteChanged,
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Divider(height: 1, thickness: 1, color: DS.outlineVariant),

          // 3. 照片
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DS.base,
              vertical: 10,
            ),
            child: Row(
              children: [
                Text(
                  '照片',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 12),
                // 添加照片（底部弹出选择）
                GestureDetector(
                  onTap: () => _showPhotoOptions(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: DS.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                      border: Border.all(
                        color: DS.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.add_a_photo, size: 18, color: DS.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 照片缩略图（如果有）
          if (images.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DS.base),
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
                          margin: EdgeInsets.only(right: DS.base),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DS.radiusSm),
                            color: DS.surfaceContainerLow,
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
                              child: Icon(Icons.close,
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
          Divider(height: 1, thickness: 1, color: DS.outlineVariant),

          // 4. 位置
          Padding(
            padding: EdgeInsets.all(DS.base),
            child: Row(
              children: [
                Text(
                  '位置',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DS.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: onLocationDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DS.secondaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: DS.secondaryContainer,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '添加位置',
                          style: TextStyle(
                            fontSize: 13,
                            color: DS.secondaryContainer,
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
              padding: EdgeInsets.symmetric(
                  horizontal: DS.base, vertical: 8),
              child: Container(
                padding: EdgeInsets.all(DS.base),
                decoration: BoxDecoration(
                  color: DS.background,
                  borderRadius: BorderRadius.circular(DS.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: DS.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location!,
                        style: TextStyle(
                          fontSize: 13,
                          color: DS.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onLocationChanged(''),
                      child: Icon(Icons.close,
                          size: 16, color: DS.outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(
          color: DS.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusMd)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: DS.primary),
              title: Text('从相册选择'),
              onTap: () {
                Navigator.pop(ctx);
                onPickImages();
              },
            ),
            if (onCaptureImage != null)
              ListTile(
                leading: Icon(Icons.camera_alt, color: DS.secondaryContainer),
                title: Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCaptureImage!();
                },
              ),
            SizedBox(height: DS.sm),
          ],
        ),
      ),
    );
  }
}
