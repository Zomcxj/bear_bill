import 'package:flutter/material.dart';

import '../../../theme/app_design_system.dart';

/// 帮助项组件
Widget _buildHelpItem(IconData icon, String title, String content) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DS.primary),
            SizedBox(width: 6),
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        SizedBox(height: 4),
        Text(content,
            style:
                DS.labelSm.copyWith(color: DS.onSurfaceVariant)),
      ],
    ),
  );
}

/// 显示使用帮助对话框
void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('使用帮助'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.edit, '手动记账', '点击首页右下角「记一笔」按钮，选择分类后输入金额即可。支持心情标签、定位、图片附件。'),
            _buildHelpItem(Icons.auto_awesome, 'AI 智能记账', '点击首页话筒按钮按住说话，或进入 AI 记账页面输入自然语言，如"午餐花了25"、"打车去公司"，AI 自动识别分类和金额。'),
            _buildHelpItem(Icons.chat, 'AI 对话查询', '在 AI 记账页面可以用自然语言查询账单，如"这个月餐饮花了多少"、"上个月交通支出"、"开心时候的消费"。'),
            _buildHelpItem(Icons.mic, '语音输入', '首页话筒按钮支持按住说话，松开自动识别并跳转 AI 记账。上滑可取消录音。'),
            _buildHelpItem(Icons.map, '消费地图', '在「设置」-「消费地图」中查看所有带定位的消费记录在地图上的分布，了解消费足迹。'),
            _buildHelpItem(Icons.leaderboard, '统计报表', '在「统计」页可切换月度/年度报表，查看收支趋势、分类占比、AI 洞察分析。'),
            _buildHelpItem(Icons.track_changes, '心愿储蓄罐', '在「心愿」页创建存钱心愿，设置心愿金额和截止日期，每次可存入部分金额。'),
            _buildHelpItem(Icons.book, '多账本', '在首页点击账本名称可切换账本，「我的」-「账本管理」中可创建多个账本分别记录。'),
            _buildHelpItem(Icons.local_fire_department, '连续打卡', '每天记账即自动打卡，断签会重置计数。等级经验：记账 +5，打卡 +10。'),
            _buildHelpItem(Icons.backup, '数据备份', '在「设置」-「导出/导入数据」可以备份数据库文件，换机时可导入恢复。'),
            _buildHelpItem(Icons.alarm, '记账提醒', '在「设置」-「记账提醒」中设置每日提醒时间，未记账时会推送通知。'),
            _buildHelpItem(Icons.smart_toy, '自动记账', '在「设置」-「自动记账」中开启微信/支付宝通知监听，收到支付通知自动记账。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('知道了'),
        ),
      ],
    ),
  );
}
