import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

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

class _MultiBookPageState extends State<MultiBookPage> {
  List<BookModel> _books = [];
  Map<String, int> _bookRecordCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
        title: const Text('切换账本'),
        content: const Text('切换后首页将显示新账本的数据'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('切换', style: TextStyle(color: AppTheme.primary)),
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

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ 编辑账本'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '账本名称',
            prefixIcon: Icon(Icons.book),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
              Navigator.pop(context, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (newName != null && newName != book.name) {
      final updatedBook = book.copyWith(name: newName);
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
        title: const Text('确认删除'),
        content: Text('确定要删除「${book.name}」吗？\n该账本下的所有账单也将被删除！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('删除', style: TextStyle(color: AppTheme.primaryDark)),
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
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text('多账本管理'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📒', style: TextStyle(fontSize: 80)),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有其他账本',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 创建新账本',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
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
        title: const Text('✨ 创建新账本'),
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
            child: const Text('取消'),
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
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: const Text('创建'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isCurrent ? _hexToColor(book.color).withOpacity(0.1) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCurrent ? _hexToColor(book.color) : AppTheme.border,
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    book.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // 账本信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          book.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text(
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
                    const SizedBox(height: 4),
                    Text(
                      '$recordCount 条记录',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
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
                        color: AppTheme.bgSection,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(Icons.edit,
                          size: 16, color: AppTheme.primary),
                    ),
                  ),
                  if (!isCurrent) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSection,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: AppTheme.textHint),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSwitch,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('切换到此账本'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _hexToColor(book.color),
                  side: BorderSide(color: _hexToColor(book.color)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
