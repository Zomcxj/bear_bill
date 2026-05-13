import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/amap_location_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/category_selector.dart';
import 'widgets/custom_keyboard.dart';
import 'widgets/map_picker_page.dart';

/// �记账页 - 支出/收入切换、分类选择、心情标签、自定义键盘
class AddRecordPage extends StatefulWidget {
  final String? preselectedCategory; // 从首页快捷入口传入的分类ID
  final String? initialType; // 初始类型：expense | income
  final RecordModel? editRecord; // 编辑模式：传入已有记录

  const AddRecordPage({super.key, this.preselectedCategory, this.initialType, this.editRecord});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  static const MethodChannel _locationChannel =
      MethodChannel('bear_bill/location');

  String _type = 'expense'; // expense | income
  String _amount = '';
  CategoryModel? _selectedCategory;
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  MoodModel? _selectedMood;
  List<String> _images = [];
  String? _location;
  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 如果传入了initialType，则使用它；否则默认为expense
    if (widget.initialType != null &&
        (widget.initialType == 'expense' || widget.initialType == 'income')) {
      _type = widget.initialType!;
    }

    // 编辑模式：用已有记录填充表单
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _type = r.type;
      _amount = r.amount.toString();
      _note = r.remark ?? '';
      _noteController.text = _note;
      _selectedDate = DateTime.parse(r.date);
      _images = List.from(r.images);
      _location = r.location;
      if (_location != null) _locationController.text = _location!;
      if (r.mood != null) {
        _selectedMood = getMoodById(r.mood!);
      }
    }

    _initCategories();

    // 编辑模式下，覆盖分类为记录的分类
    if (widget.editRecord != null) {
      final categories = _type == 'expense' ? expenseCategories : incomeCategories;
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.editRecord!.categoryId,
        orElse: () => categories.first,
      );
    }
  }

  void _initCategories() {
    final categories =
        _type == 'expense' ? expenseCategories : incomeCategories;

    if (widget.preselectedCategory != null) {
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.preselectedCategory,
        orElse: () => categories.first,
      );
    } else {
      _selectedCategory = categories.first;
    }
  }

  void _switchType(String type) {
    if (_type == type) return;

    setState(() {
      _type = type;
      _amount = '';
      _initCategories();
    });
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _handleKeyInput(String key) {
    if (key == '备注') {
      _noteFocusNode.requestFocus();
      return;
    }

    if (key == '完成') {
      _submitRecord();
      return;
    }

    setState(() {
      _amount = utils.FormatUtils.handleAmountInput(_amount, key);
    });
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _images.addAll(result.paths.whereType<String>());
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitRecord() async {
    if (_amount.isEmpty || double.tryParse(_amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final amount = double.parse(_amount);

    // 使用 utils 中的 DateUtils，避免与 Flutter 的 DateUtils 冲突
    final dateStr = utils.DateUtils.formatDate(_selectedDate);
    final monthStr = dateStr.substring(0, 7); // 'YYYY-MM'
    final dateTs = _selectedDate.millisecondsSinceEpoch;

    final isEdit = widget.editRecord != null;

    final record = RecordModel(
      id: isEdit ? widget.editRecord!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: appProvider.currentBookId,
      type: _type,
      amount: amount,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.icon,
      categoryColor: _selectedCategory!.color,
      remark: _note,
      date: dateStr,
      month: monthStr,
      dateTs: dateTs,
      mood: _selectedMood?.id,
      moodEmoji: _selectedMood?.emoji,
      images: _images,
      location: _location,
      createdAt: isEdit ? widget.editRecord!.createdAt : DateTime.now(),
    );

    if (isEdit) {
      await DatabaseService.instance.updateRecord(record);
    } else {
      await DatabaseService.instance.insertRecord(record);
    }

    // 更新今日记账摘要（通知显示总结）
    NotificationService.instance.refreshTodaySummary();

    // 显示成功提示
    if (mounted) {
      if (!isEdit) {
        // 新记录才触发打卡和成就检查
        final achievements = await appProvider.onRecordAdded(
          type: _type,
          amount: amount,
        );
        // 自动打卡（已打卡则幂等跳过）
        final checkInAchievements = await appProvider.recordCheckIn();
        achievements.addAll(checkInAchievements);
        if (achievements.isNotEmpty) {
          _showAchievementDialog(achievements);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '记账成功！${_type == 'expense' ? '-' : '+'}¥${utils.FormatUtils.formatAmount(amount)}'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // 新记录：重置表单状态，允许连续记账
        setState(() {
          _amount = '';
          _note = '';
          _noteController.clear();
          _selectedMood = null;
          _selectedDate = DateTime.now();
          _images = [];
          _location = null;
          _locationController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修改成功！'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // 延迟后返回
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _showAchievementDialog(List<dynamic> achievements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 解锁新成就！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((a) {
            return ListTile(
              leading: Text(a.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(a.title),
              subtitle: Text(a.description),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AppProvider>().clearNewAchievements();
              Navigator.pop(context);
            },
            child: const Text('太棒了！'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _type == 'expense' ? expenseCategories : incomeCategories;
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✏️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '记一笔',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 类型切换 - 支出/收入
                  _buildTypeSwitcher(),

                  // 2. 金额区域（粉色背景）
                  _buildAmountAndDateSection(),

                  // 3. 分类选择器
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: CategorySelector(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onSelect: _selectCategory,
                    ),
                  ),

                  // 4. 底部信息模块
                  _buildBottomInfoCard(),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: CustomKeyboard(onKeyTap: _handleKeyInput),
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchType('expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _type == 'expense'
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    '💸 支出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _type == 'expense'
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchType('income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      _type == 'income' ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    '💰 收入',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _type == 'income'
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library),
            label: const Text('添加图片'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          // 缩略图区域：如果有图片则横向滚动显示缩略图，放在按钮右侧
          Expanded(
            child: _images.isNotEmpty
                ? SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final path = _images[index];
                        return Stack(
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                color: Colors.grey[200],
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
                                onTap: () => _removeImageAt(index),
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
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: TextField(
        controller: _locationController,
        decoration: InputDecoration(
          hintText: '位置（可选）',
          prefixIcon: const Icon(Icons.place, color: AppTheme.textHint),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none),
        ),
        onChanged: (v) => _location = v,
      ),
    );
  }

  Widget _buildAmountAndDateSection() {
    final panelColor = AppTheme.primaryLight;
    final accentColor =
        _type == 'expense' ? AppTheme.primaryDark : AppTheme.primary;

    return Container(
      color: panelColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: accentColor.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildInfoPill(
                      icon: _selectedCategory?.icon ?? '🍜',
                      label: _selectedCategory?.name ?? '餐饮',
                      backgroundColor: AppTheme.primary,
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: _buildInfoPill(
                        icon: '📅',
                        label:
                            '${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        backgroundColor: const Color(0xFFF7F7F8),
                        textColor: AppTheme.textPrimary,
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _amount.isEmpty ? '¥0' : '¥$_amount',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['10', '20', '50', '100', '200', '500'].map((amount) {
                final isSelected = _amount == amount;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _amount = amount;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : accentColor.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        '¥$amount',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required String icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInfoCard() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
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
                const Text(
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
                        final isSelected = _selectedMood?.id == mood.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMood = mood;
                              });
                            },
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
                const Text(
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
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    maxLength: 50,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: '点这里补一句备注',
                      hintStyle: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(left: 8),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      _note = value;
                    },
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
                const Text(
                  '照片',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _pickImages,
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
                        Icons.camera_alt,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 照片缩略图（如果有）
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final path = _images[index];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            color: Colors.grey[200],
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
                            onTap: () => _removeImageAt(index),
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
                const Text(
                  '位置',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showLocationDialog,
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
          if (_location != null && _location!.isNotEmpty)
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
                        _location!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _location = null;
                          _locationController.clear();
                        });
                      },
                      child: const Icon(Icons.close,
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

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _selectDate() async {
    DateTime tempDate = _selectedDate;
    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context, tempDate),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(2020),
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        _showSnackBar('请先开启系统定位服务，再重新尝试定位');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        _showSnackBar('请允许位置权限以获取定位');
        return;
      }

      _showSnackBar('正在定位...');

      // 优先使用上次已知位置（快速返回）
      Position? position = await Geolocator.getLastKnownPosition();

      // 如果没有缓存位置，再请求实时定位
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (_) {
          // 超时或失败，尝试低精度
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 8),
            );
          } catch (_) {}
        }
      }

      if (position == null) {
        _showSnackBar('未获取到定位结果，请尝试地图选点');
        return;
      }

      // 反向地理编码（优先高德 API → 原生 Geocoder → 坐标）
      final coordStr = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      String address = coordStr;
      try {
        final amap = AmapLocationService.instance;
        if (amap.isConfigured) {
          final result = await amap.reverseGeocode(position.latitude, position.longitude);
          if (result != null && result.fullAddress.isNotEmpty) {
            address = result.fullAddress;
          }
        }
        // 如果高德未返回有效地址，回退到原生 Geocoder
        if (address == coordStr && Platform.isAndroid) {
          final nativeResult = await _locationChannel.invokeMethod<String>(
            'reverseGeocode',
            {'latitude': position.latitude, 'longitude': position.longitude},
          );
          if (nativeResult != null && nativeResult.trim().isNotEmpty) {
            address = nativeResult.trim();
          }
        }
      } catch (e) {
        print('反向编码异常: $e');
      }

      setState(() {
        _location = address;
        _locationController.text = address;
      });

      _showSnackBar('定位成功');
    } catch (e) {
      _showSnackBar('定位失败，请尝试地图选点');
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  /// 打开应用内地图选点（类似微信位置选择）
  Future<void> _openMapPicker() async {
    LatLng? initialCenter;

    // 尝试获取当前位置作为地图初始中心
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            initialCenter = LatLng(position.latitude, position.longitude);
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialCenter: initialCenter,
          initialName: _location,
        ),
      ),
    );

    if (result != null && mounted) {
      final name = result['name'] as String? ?? '';
      setState(() {
        _location = name.isNotEmpty ? name : _location;
        _locationController.text = _location ?? '';
      });
    }
  }

  Future<void> _showLocationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 添加位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 手动输入
            ListTile(
              leading: Icon(Icons.edit_location, color: AppTheme.primary),
              title: const Text('手动输入'),
              subtitle: const Text('直接输入地点名称'),
              onTap: () {
                Navigator.pop(context);
                _showManualInputDialog();
              },
            ),
            const Divider(height: 1),
            // GPS定位
            ListTile(
              leading: const Icon(Icons.my_location, color: AppTheme.info),
              title: const Text('GPS定位'),
              subtitle: const Text('获取当前设备位置'),
              onTap: () {
                Navigator.pop(context);
                _fetchDeviceLocation();
              },
            ),
            const Divider(height: 1),
            // 地图选点
            ListTile(
              leading: const Icon(Icons.map, color: AppTheme.success),
              title: const Text('地图选点'),
              subtitle: const Text('打开地图搜索和选择位置'),
              onTap: () {
                Navigator.pop(context);
                _openMapPicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 手动输入位置对话框
  Future<void> _showManualInputDialog() async {
    final controller = TextEditingController(text: _location ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入位置'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入地点、地址或门店名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  _location = value;
                  _locationController.text = value;
                });
              }
              Navigator.pop(context);
            },
            child: Text('保存', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
