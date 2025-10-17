import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double phone = 720;
  static const double tablet = 1024;

  static DeviceSize sizeForWidth(double width) {
    if (width < phone) return DeviceSize.phone;
    if (width < tablet) return DeviceSize.tablet;
    return DeviceSize.desktop;
  }

  static DeviceSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return sizeForWidth(width);
  }

  static bool isPhone(BuildContext context) =>
      of(context) == DeviceSize.phone;

  static bool isTablet(BuildContext context) =>
      of(context) == DeviceSize.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceSize.desktop;
}

enum DeviceSize { phone, tablet, desktop }
