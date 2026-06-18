import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../services/database_backup_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../map_footprint/map_footprint_page.dart';
import 'auto_record_settings.dart';
import 'settings_dialogs.dart';

/// 设置列表
class SettingsList extends StatelessWidget {
  final VoidCallback onClearData;

  const SettingsList({super.key, required this.onClearData});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _buildMenuItem(
            emoji: '💰',
            title: '每月预算',
            onTap: () => showBudgetDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🔔',
            title: '记账提醒',
            onTap: () => showReminderDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🤖',
            title: '自动记账',
            trailing: '微信/支付宝',
            onTap: () => showAutoRecordDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '📤',
            title: '导出数据',
            onTap: () async {
              await DatabaseBackupService.instance.exportDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '📥',
            title: '导入数据',
            onTap: () async {
              await DatabaseBackupService.instance.importDatabase(context);
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🔤',
            title: '字号调整',
            onTap: () => showFontSizeDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🎨',
            title: '主题颜色',
            onTap: () => showThemeColorDialog(
              context,
              context.read<ThemeProvider>(),
            ),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🗺️',
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
            emoji: '📖',
            title: '使用帮助',
            onTap: () => showHelpDialog(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: 'ℹ️',
            title: '关于',
            trailing: 'v1.2.1',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小熊记账本',
                applicationVersion: 'v1.2.1',
                applicationIcon:
                    const Text('🐻', style: TextStyle(fontSize: 48)),
                children: [
                  const Text('软萌粉糖色系记账应用'),
                  const SizedBox(height: 8),
                  const Text('让记账变得有趣又可爱～'),
                ],
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            emoji: '🗑️',
            title: '清空账单',
            isDanger: true,
            onTap: onClearData,
          ),
        ],
      ),
    );
  }

  /// 菜单项（对齐小程序 menu-item 样式）
  Widget _buildMenuItem({
    required String emoji,
    required String title,
    String? trailing,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDanger ? AppTheme.primaryDark : AppTheme.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                ),
              ),
            const SizedBox(width: 4),
            Text(
              '›',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textHint.withOpacity(0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppTheme.divider);
  }
}
