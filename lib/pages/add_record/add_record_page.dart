import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/bottom_info_card.dart';
import 'widgets/category_selector.dart';
import 'widgets/custom_keyboard.dart';
import 'widgets/location_helper.dart';

/// �记账页 - 支出/收入切换、分类选择、心情标签、自定义键盘
class AddRecordPage extends StatefulWidget {
  final String? preselectedCategory; // 从首页快捷入口传入的分类ID
  final String? initialType; // 初始类型：expense | income
  final RecordModel? editRecord; // 编辑模式：传入已有记录
  final RecordModel? prefillRecord; // 预填模式：从AI记账传入，新建但预填数据

  const AddRecordPage({super.key, this.preselectedCategory, this.initialType, this.editRecord, this.prefillRecord});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> with LocationHelper {

  String _type = 'expense'; // expense | income
  String _amount = '';
  CategoryModel? _selectedCategory;
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  MoodModel? _selectedMood;
  List<String> _images = [];
  String? _location;
  double? _latitude;
  double? _longitude;
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

    // 编辑模式或预填模式：用记录填充表单
    final prefill = widget.editRecord ?? widget.prefillRecord;
    if (prefill != null) {
      _type = prefill.type;
      _amount = prefill.amount.toString();
      _note = prefill.remark ?? '';
      _noteController.text = _note;
      _selectedDate = DateTime.parse(prefill.date);
      _images = List.from(prefill.images);
      _location = prefill.location;
      _latitude = prefill.latitude;
      _longitude = prefill.longitude;
      if (_location != null) _locationController.text = _location!;
      if (prefill.mood != null) {
        _selectedMood = getMoodById(prefill.mood!);
      }
    }

    _initCategories();

    // 编辑模式或预填模式下，覆盖分类为记录的分类
    if (prefill != null) {
      final categories = _type == 'expense' ? expenseCategories : incomeCategories;
      _selectedCategory = categories.firstWhere(
        (c) => c.id == prefill.categoryId,
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
      final newImages = await ImageService.instance.pickAndCopyImages();
      if (newImages.isNotEmpty) {
        setState(() {
          _images.addAll(newImages);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _captureImage() async {
    try {
      final newImage = await ImageService.instance.captureFromCamera();
      if (newImage != null) {
        setState(() {
          _images.add(newImage);
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
    final amount = double.parse(_amount);
    if (amount > 99999999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金额不能超过 99,999,999')),
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
      latitude: _latitude,
      longitude: _longitude,
      createdAt: isEdit ? widget.editRecord!.createdAt : DateTime.now(),
    );

    if (isEdit) {
      await DatabaseService.instance.updateRecord(record);
    } else {
      await DatabaseService.instance.insertRecord(record);
    }

    // 保存到常去地点
    if (_location != null && _location!.isNotEmpty && _latitude != null && _longitude != null) {
      await DatabaseService.instance.upsertFavoriteLocation(
        name: _location!,
        address: _location!,
        latitude: _latitude!,
        longitude: _longitude!,
      );
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
        if (!mounted) return;
        achievements.addAll(checkInAchievements);
        if (achievements.isNotEmpty) {
          _showAchievementDialog(achievements);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '记账成功！${_type == 'expense' ? '-' : '+'}¥${utils.FormatUtils.formatAmount(amount)}'),
              backgroundColor: DS.secondary,
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
          _latitude = null;
          _longitude = null;
          _locationController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('修改成功！'),
            backgroundColor: DS.secondary,
            duration: Duration(seconds: 1),
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
        title: Text('🎉 解锁新成就！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((a) {
            return ListTile(
              leading: Text(a.emoji, style: TextStyle(fontSize: 32)),
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
            child: Text('太棒了！'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    final categories =
        _type == 'expense' ? expenseCategories : incomeCategories;
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 渐变 Hero 区域：标题 + 类型切换 + 金额 + 日期 + 分类
            Container(
              padding: EdgeInsets.fromLTRB(
                DS.containerMargin,
                MediaQuery.of(context).padding.top + DS.gutter,
                DS.containerMargin,
                DS.base,
              ),
              decoration: BoxDecoration(
                gradient: DS.heroGradientBlueCurrent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DS.radiusLg),
                  bottomRight: Radius.circular(DS.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题 + 返回
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios, size: 20, color: DS.onSurface),
                      ),
                      SizedBox(width: DS.sm),
                      Icon(Icons.edit, size: 20, color: DS.onSurface),
                      SizedBox(width: DS.xs),
                      Text('记一笔', style: DS.headlineMd),
                    ],
                  ),
                  SizedBox(height: DS.base),
                  // 支出/收入切换
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: DS.heroCardBg,
                      borderRadius: BorderRadius.circular(DS.radiusFull),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchType('expense'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: DS.sm),
                              decoration: BoxDecoration(
                                color: _type == 'expense' ? DS.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(DS.radiusFull),
                              ),
                              child: Center(
                                child: Text('支出', style: DS.labelMd.copyWith(
                                  color: _type == 'expense' ? DS.onPrimary : DS.onSurface,
                                )),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchType('income'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: DS.sm),
                              decoration: BoxDecoration(
                                color: _type == 'income' ? DS.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(DS.radiusFull),
                              ),
                              child: Center(
                                child: Text('收入', style: DS.labelMd.copyWith(
                                  color: _type == 'income' ? DS.onPrimary : DS.onSurface,
                                )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DS.base),
                  // 金额 + 日期
                  _buildAmountRow(),
                  SizedBox(height: DS.base),
                  // 分类选择器
                  CategorySelector(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelect: _selectCategory,
                  ),
                ],
              ),
            ),

          // 底部信息模块
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: DS.base),
                  BottomInfoCard(
                    selectedMood: _selectedMood,
                    onMoodChanged: (mood) => setState(() => _selectedMood = mood),
                    noteController: _noteController,
                    noteFocusNode: _noteFocusNode,
                    onNoteChanged: (v) => _note = v,
                    images: _images,
                    onPickImages: _pickImages,
                    onCaptureImage: _captureImage,
                    onRemoveImage: _removeImageAt,
                    location: _location,
                    onLocationChanged: (v) {
                      setState(() {
                        _location = v.isEmpty ? null : v;
                        if (v.isEmpty) _locationController.clear();
                      });
                    },
                    locationController: _locationController,
                    onLocationDialog: _handleLocationDialog,
                  ),

                  SizedBox(height: DS.gutter),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        child: CustomKeyboard(onKeyTap: _handleKeyInput),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color: DS.heroCardBg,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: DS.heroCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类 + 日期标签
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
                decoration: BoxDecoration(
                  color: DS.primary,
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedCategory?.icon ?? '🍜', style: TextStyle(fontSize: 14)),
                    SizedBox(width: DS.xs),
                    Text(
                      _selectedCategory?.name ?? '餐饮',
                      style: DS.labelSm.copyWith(color: DS.onPrimary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: DS.sm),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
                  decoration: BoxDecoration(
                    color: DS.heroCardBg,
                    borderRadius: BorderRadius.circular(DS.radiusFull),
                    border: Border.all(color: DS.heroCardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: DS.onSurface),
                      SizedBox(width: DS.xs),
                      Text(
                        '${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: DS.labelSm.copyWith(color: DS.onSurface),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: DS.outline),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DS.sm),
          // 金额
          Text(
            _amount.isEmpty ? '¥0' : '¥$_amount',
            style: TextStyle(
              fontFamily: DS.fontDisplay,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: DS.onSurface,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime tempDate = _selectedDate;
    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: DS.surfaceContainerLowest,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Future<void> _handleLocationDialog() async {
    final result = await showLocationDialog();
    if (result != null && mounted) {
      setState(() {
        if (result.name != null) {
          _location = result.name;
          _locationController.text = _location ?? '';
        }
        if (result.latitude != null) _latitude = result.latitude;
        if (result.longitude != null) _longitude = result.longitude;
      });
    }
  }
}
