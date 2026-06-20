import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/amap_location_service.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/amount_date_section.dart';
import 'widgets/bottom_info_card.dart';
import 'widgets/category_selector.dart';
import 'widgets/custom_keyboard.dart';
import 'widgets/map_picker_page.dart';
import 'widgets/type_switcher.dart';

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
      _latitude = r.latitude;
      _longitude = r.longitude;
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
          _latitude = null;
          _longitude = null;
          _locationController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('修改成功！'),
            backgroundColor: AppTheme.success,
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
                  TypeSwitcher(
                    type: _type,
                    onTypeChanged: _switchType,
                  ),

                  // 2. 金额区域（粉色背景）
                  AmountDateSection(
                    amount: _amount,
                    type: _type,
                    selectedCategory: _selectedCategory,
                    selectedDate: _selectedDate,
                    onAmountChanged: (v) => setState(() => _amount = v),
                    onDateSelect: _selectDate,
                  ),

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
                    onLocationDialog: _showLocationDialog,
                  ),

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

  Future<void> _selectDate() async {
    DateTime tempDate = _selectedDate;
    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: AppTheme.bgCard,
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

      // 如果没有缓存位置，再请求实时定位（多次尝试，精度递减）
      // forceAndroidLocationManager=true 避免依赖 Google Play Services（国产手机兼容性更好）
      if (position == null) {
        final accuracies = [
          LocationAccuracy.high,
          LocationAccuracy.medium,
          LocationAccuracy.low,
        ];
        for (final acc in accuracies) {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: acc,
              timeLimit: const Duration(seconds: 15),
              forceAndroidLocationManager: true,
            );
            break;
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
        if (kDebugMode) print('反向编码异常: $e');
      }

      setState(() {
        _location = address;
        _locationController.text = address;
        _latitude = position?.latitude;
        _longitude = position?.longitude;
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
      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      setState(() {
        _location = name.isNotEmpty ? name : _location;
        _locationController.text = _location ?? '';
        _latitude = lat;
        _longitude = lng;
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
