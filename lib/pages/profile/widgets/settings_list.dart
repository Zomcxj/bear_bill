import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../services/database_backup_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';
import '../../map_footprint/map_footprint_page.dart';
import 'auto_record_settings.dart';
import 'settings_dialogs.dart';

/// 设置列表
class SettingsList extends StatefulWidget {
  final VoidCallback onClearData;

  const SettingsList({super.key, required this.onClearData});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DS.sm),
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.savings,
            title: '每月预算',
            onTap: () => showBudgetDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications,
            title: '记账提醒',
            trailing: _getReminderTimeText(),
            onTap: () async {
              await showReminderDialog(context);
              if (mounted) setState(() {});
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.map,
            title: '消费地图',
            trailing: '足迹',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapFootprintPage()),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.smart_toy,
            title: '自动记账',
            trailing: '通知监听',
            onTap: () => showAutoRecordDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.upload,
            title: '导出数据',
            onTap: () async {
              await DatabaseBackupService.instance.exportDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.download,
            title: '导入数据',
            onTap: () async {
              await DatabaseBackupService.instance.importDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.text_fields,
            title: '字号调整',
            onTap: () => showFontSizeDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.dark_mode,
            title: '深色模式',
            trailing: context.watch<ThemeProvider>().isDarkMode ? '已开启' : '已关闭',
            onTap: () => context.read<ThemeProvider>().toggleDarkMode(),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '使用帮助',
            onTap: () => showHelpDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '关于',
            trailing: 'v1.3.5',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小熊记账本',
                applicationVersion: 'v1.3.5',
                applicationIcon:
                    Text('🐻', style: TextStyle(fontSize: 48)),
                children: [
                  Text('软萌粉糖色系记账应用'),
                  SizedBox(height: 8),
                  Text('让记账变得有趣又可爱～'),
                ],
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: '清空账单',
            isDanger: true,
            onTap: widget.onClearData,
          ),
        ],
      ),
    );
  }

  /// 菜单项（使用 Material Icons + DS 设计系统）
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailing,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DS.sm,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DS.onSurface),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: DS.bodyMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DS.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: DS.labelSm.copyWith(color: DS.outline),
              ),
            SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: DS.outline.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: DS.outlineVariant);
  }

  String _getReminderTimeText() {
    final storage = StorageService.instance;
    final hour = storage.getString('reminderHour');
    final minute = storage.getString('reminderMinute');
    if (hour == null || hour.isEmpty || minute == null || minute.isEmpty) {
      return '未开启';
    }
    return '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')}';
  }
}
