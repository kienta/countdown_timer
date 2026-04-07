import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Number of columns for grid layout
  static int gridColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        final width = MediaQuery.of(context).size.width;
        if (width >= 1400) return 4;
        return 3;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }

  /// Timer detail layout: side-by-side on desktop/tablet, stacked on mobile
  static bool useHorizontalTimerLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= 500;
  }

  /// Max width for content area
  static double maxContentWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 1200;
      case DeviceType.tablet:
        return 800;
      case DeviceType.mobile:
        return double.infinity;
    }
  }

  /// Dialog width
  static double dialogWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 420;
      case DeviceType.tablet:
        return 400;
      case DeviceType.mobile:
        return MediaQuery.of(context).size.width * 0.9;
    }
  }

  /// Countdown font size
  static double countdownFontSize(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 42;
      case DeviceType.tablet:
        return 36;
      case DeviceType.mobile:
        return 28;
    }
  }

  /// Hourglass size
  static double hourglassSize(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 120;
      case DeviceType.tablet:
        return 100;
      case DeviceType.mobile:
        return 80;
    }
  }

  /// Padding
  static EdgeInsets screenPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return const EdgeInsets.all(20);
      case DeviceType.tablet:
        return const EdgeInsets.all(16);
      case DeviceType.mobile:
        return const EdgeInsets.all(12);
    }
  }
}

/// A responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, Responsive.getDeviceType(context));
      },
    );
  }
}
