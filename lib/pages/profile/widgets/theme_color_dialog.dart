import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';

/// 显示主题颜色选择对话框
void showThemeColorDialog(BuildContext context, ThemeProvider themeProvider) {
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('主题颜色'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: ThemeProvider.paletteColors.length,
              itemBuilder: (_, index) {
                final color = ThemeProvider.paletteColors[index];
                final isSelected =
                    themeProvider.primaryColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    themeProvider.setPrimaryColor(color);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('主题颜色已更换'),
                        backgroundColor: AppTheme.success,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            color: Colors.white, size: 28)
                        : null,
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.dark_mode, size: 20, color: DS.onSurface),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '深色模式',
                      style: DS.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: DS.onSurface,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) {
                        themeProvider.toggleDarkMode();
                        setDialogState(() {});
                      },
                      activeColor: DS.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showCustomColorPicker(context, themeProvider);
                },
                icon: Icon(Icons.palette, size: 18),
                label: Text('自定义颜色'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DS.primary,
                  side: BorderSide(color: DS.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('关闭'),
        ),
      ],
    ),
  ),
  );
}

/// 自定义颜色选择器（HSV 色盘 + 明度条）
void showCustomColorPicker(
    BuildContext context, ThemeProvider themeProvider) {
  showDialog(
    context: context,
    builder: (ctx) => ColorPickerDialog(
      initialColor: themeProvider.primaryColor,
      onConfirm: (color) {
        themeProvider.setPrimaryColor(color);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('主题颜色已更换'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 1),
          ),
        );
      },
    ),
  );
}

/// HSV 颜色选择器对话框
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onConfirm;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onConfirm,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final selectedColor = _hsv.toColor();
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette, color: DS.primary, size: 24),
          SizedBox(width: 8),
          Text('自定义颜色'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(DS.radiusSm),
              border: Border.all(color: DS.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _hsv.saturation > 0.3 && _hsv.value > 0.5
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildSlider(
            label: '色相',
            value: _hsv.hue,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0.3, 1).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          SizedBox(height: 12),
          _buildSlider(
            label: '饱和',
            value: _hsv.saturation,
            max: 1,
            activeColor: _hsv.toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          SizedBox(height: 12),
          _buildSlider(
            label: '明度',
            value: _hsv.value,
            max: 1,
            min: 0.2,
            activeColor: _hsv.toColor(),
            inactiveColor: HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0.2).toColor(),
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(selectedColor);
            Navigator.pop(context);
          },
          child: Text('确认', style: TextStyle(color: DS.primary)),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    double min = 0,
    required Color activeColor,
    required Color inactiveColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              inactiveTrackColor: inactiveColor,
              overlayColor: Colors.transparent,
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
