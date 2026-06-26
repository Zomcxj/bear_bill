import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/app_design_system.dart';

void main() {
  group('DS 深色模式', () {
    tearDown(() {
      DS.setDarkMode(false);
    });

    test('默认浅色模式', () {
      expect(DS.isDark, false);
    });

    test('setDarkMode 切换深色模式', () {
      DS.setDarkMode(true);
      expect(DS.isDark, true);

      DS.setDarkMode(false);
      expect(DS.isDark, false);
    });

    test('background 浅色/深色不同', () {
      DS.setDarkMode(false);
      final lightBg = DS.background;

      DS.setDarkMode(true);
      final darkBg = DS.background;

      expect(lightBg, isNot(equals(darkBg)));
    });

    test('onSurface 浅色深色不同', () {
      DS.setDarkMode(false);
      final lightText = DS.onSurface;

      DS.setDarkMode(true);
      final darkText = DS.onSurface;

      expect(lightText, isNot(equals(darkText)));
    });

    test('surfaceContainerLowest 浅色为白色，深色为深色', () {
      DS.setDarkMode(false);
      expect(DS.surfaceContainerLowest, Colors.white);

      DS.setDarkMode(true);
      expect(DS.surfaceContainerLowest, isNot(equals(Colors.white)));
    });

    test('heroCardBg 浅色/深色透明度不同', () {
      DS.setDarkMode(false);
      final lightCard = DS.heroCardBg;

      DS.setDarkMode(true);
      final darkCard = DS.heroCardBg;

      expect(darkCard.opacity, lessThan(lightCard.opacity));
    });

    test('errorDynamic 浅色/深色不同', () {
      DS.setDarkMode(false);
      final lightError = DS.errorDynamic;

      DS.setDarkMode(true);
      final darkError = DS.errorDynamic;

      expect(lightError, isNot(equals(darkError)));
    });

    test('常量颜色不随深色模式变化', () {
      DS.setDarkMode(false);
      final lightPrimary = DS.primary;
      final lightError = DS.error;

      DS.setDarkMode(true);
      final darkPrimary = DS.primary;
      final darkError = DS.error;

      expect(lightPrimary, equals(darkPrimary));
      expect(lightError, equals(darkError));
    });

    test('圆角常量正确', () {
      expect(DS.radiusXs, 8);
      expect(DS.radiusSm, 12);
      expect(DS.radiusMd, 16);
      expect(DS.radiusLg, 32);
      expect(DS.radiusXl, 48);
      expect(DS.radiusFull, 999);
    });

    test('间距常量正确', () {
      expect(DS.xs, 4);
      expect(DS.base, 8);
      expect(DS.sm, 12);
      expect(DS.gutter, 16);
      expect(DS.md, 24);
      expect(DS.lg, 40);
      expect(DS.xl, 64);
    });
  });
}
