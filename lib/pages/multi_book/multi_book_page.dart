import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';

/// 将 hex 颜色字符串转换为 Color
Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// 多账本管理页 - 创建/切换/删除账本
class MultiBookPage extends StatefulWidget {
  const MultiBookPage({super.key});

  @override
  State<MultiBookPage> createState() => _MultiBookPageState();
}

class _MultiBookPageState extends State<MultiBookPage> with RouteAware {
  List<BookModel> _books = [];
  Map<String, int> _bookRecordCounts = {};
  bool _loading = true;
  RouteObserver<ModalRoute<void>>? _routeObserver;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver ??= Navigator.of(context).widget.observers
        .whereType<RouteObserver<ModalRoute<void>>>()
        .firstOrNull;
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 从其他页面返回时刷新数据
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);

    final books = await DatabaseService.instance.getAllBooks();

    // 查询每个账本的记录数
    final countMap = <String, int>{};
    for (final book in books) {
      final count = await DatabaseService.instance.getTotalRecordsCount(
        bookId: book.id,
      );
      countMap[book.id] = count;
    }

    setState(() {
      _books = books;
      _bookRecordCounts = countMap;
      _loading = false;
    });
  }

  Future<void> _createBook(String name) async {
    final book = BookModel(
      id: const Uuid().v4(),
      name: name,
      icon: '📒',
      color: '#4ECDC4',
      memberOpenids: [],
      budget: 0.0,
      totalRecords: 0,
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.insertBook(book);
    _loadBooks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('账本已创建'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _switchBook(BookModel book) async {
    final appProvider = context.read<AppProvider>();

    if (book.id == appProvider.currentBookId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是当前账本')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('切换账本'),
        content: Text('切换后首页将显示新账本的数据'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('切换', style: TextStyle(color: DS.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await appProvider.switchBook(book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已切换'),
            backgroundColor: AppTheme.success,
          ),
        );

        // 延迟返回，让用户看到提示
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    }
  }

  Future<void> _editBook(BookModel book) async {
    final controller = TextEditingController(text: book.name);
    String selectedIcon = book.icon;

    const bookEmojis = [
      '📒', '📕', '📗', '📘', '📙', '📓', '📔', '💰', '🏦', '💳',
      '🏠', '✈️', '🎓', '💼', '🛒', '🎮', '🍳', '🚗', '❤️', '⭐',
    ];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: DS.primary, size: 24),
              SizedBox(width: 8),
              Text('编辑账本'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('账本图标', style: DS.labelMd),
                SizedBox(height: DS.sm),
                Wrap(
                  spacing: DS.sm,
                  runSpacing: DS.sm,
                  children: bookEmojis.map((emoji) {
                    final isSelected = selectedIcon == emoji;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = emoji),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? DS.secondaryContainer : DS.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(DS.radiusSm),
                          border: Border.all(
                            color: isSelected ? DS.secondary : DS.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(child: Text(emoji, style: TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: DS.gutter),
                Text('账本名称', style: DS.labelMd),
                SizedBox(height: DS.sm),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: '输入账本名称'),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入账本名称')),
                  );
                  return;
                }
                Navigator.pop(context, {'name': name, 'icon': selectedIcon});
              },
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedBook = book.copyWith(name: result['name'], icon: result['icon']);
      await DatabaseService.instance.updateBook(updatedBook);
      if (!mounted) return;
      _loadBooks();

      // 通知 AppProvider 刷新，以更新首页的账本名称显示
      final appProvider = context.read<AppProvider>();
      appProvider.refreshCurrentBook();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('账本已更新'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除「${book.name}」吗？\n该账本下的所有账单也将被删除！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('删除', style: TextStyle(color: DS.primaryContainer)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 先清空账单
      await DatabaseService.instance.clearRecordsByBook(book.id);
      // 再删除账本
      await DatabaseService.instance.deleteBook(book.id);
      _loadBooks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Scaffold(
      backgroundColor: DS.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 渐变 Hero 头部
            Container(
              padding: EdgeInsets.fromLTRB(DS.containerMargin, MediaQuery.of(context).padding.top + DS.gutter, DS.containerMargin, DS.base),
              decoration: BoxDecoration(
                gradient: DS.heroGradientBlueCurrent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DS.radiusLg),
                  bottomRight: Radius.circular(DS.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios, size: 20, color: DS.onSurface),
                  ),
                  SizedBox(width: DS.sm),
                  Icon(Icons.book, size: 22, color: DS.onSurface),
                  SizedBox(width: DS.sm),
                  Text('账本管理', style: DS.headlineMd),
                  Spacer(),
                  GestureDetector(
                    onTap: _showCreateDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs + 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: DS.onSurface),
                          SizedBox(width: DS.xs),
                          Text('新建', style: DS.labelSm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DS.base),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: DS.secondaryContainer))
                  : _books.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                  padding: EdgeInsets.only(left: DS.base, right: DS.base, bottom: DS.base),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Consumer<AppProvider>(
                      builder: (context, appProvider, child) {
                        final isCurrent = book.id == appProvider.currentBookId;
                        return _BookCard(
                          book: book,
                          recordCount: _bookRecordCounts[book.id] ?? 0,
                          isCurrent: isCurrent,
                          onSwitch: () => _switchBook(book),
                          onEdit: () => _editBook(book),
                          onDelete: () => _deleteBook(book),
                        );
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: DS.outlineVariant),
          SizedBox(height: DS.gutter),
          Text(
            '还没有其他账本',
            style: DS.headlineSm.copyWith(color: DS.onSurface),
          ),
          SizedBox(height: 8),
          Text(
            '点击右上角 + 创建新账本',
            style: DS.bodyMd.copyWith(color: DS.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: DS.primary, size: 24),
            SizedBox(width: 8),
            Text('创建新账本'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '账本名称',
            hintText: '例如：旅行账本、家庭账本',
            prefixIcon: Icon(Icons.book),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入账本名称')),
                );
                return;
              }
              _createBook(name);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DS.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusFull),
              ),
            ),
            child: Text('创建'),
          ),
        ],
      ),
    );
  }
}

/// 账本卡片
class _BookCard extends StatelessWidget {
  final BookModel book;
  final int recordCount;
  final bool isCurrent;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.recordCount,
    required this.isCurrent,
    required this.onSwitch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Container(
      margin: EdgeInsets.only(bottom: DS.base),
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color:
            isCurrent ? _hexToColor(book.color).withOpacity(0.1) : DS.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(
          color: isCurrent ? _hexToColor(book.color) : DS.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 账本图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _hexToColor(book.color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                ),
                child: Center(
                  child: Text(
                    book.icon,
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),

              SizedBox(width: DS.gutter),

              // 账本信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          book.name,
                          style: DS.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DS.onSurface,
                          ),
                        ),
                        if (isCurrent) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius:
                                  BorderRadius.circular(DS.radiusFull),
                            ),
                            child: Text(
                              '当前',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$recordCount 条记录',
                      style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // 操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: DS.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(DS.radiusFull),
                        border: Border.all(color: DS.outlineVariant),
                      ),
                      child: Icon(Icons.edit,
                          size: 16, color: DS.primary),
                    ),
                  ),
                  if (!isCurrent) ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: DS.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                          border: Border.all(color: DS.outlineVariant),
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: DS.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!isCurrent) ...[
            SizedBox(height: DS.gutter),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSwitch,
                icon: Icon(Icons.swap_horiz, size: 18),
                label: Text('切换到此账本'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _hexToColor(book.color),
                  side: BorderSide(color: _hexToColor(book.color)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
