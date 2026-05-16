import 'package:flutter/painting.dart' show FontWeight;

/// Standard resume font weights supported in preview and PDF export.
abstract final class ResumeFontWeight {
  static const int w100 = 100;
  static const int w200 = 200;
  static const int w300 = 300;
  static const int w400 = 400;
  static const int w500 = 500;
  static const int w600 = 600;
  static const int w700 = 700;
  static const int w800 = 800;

  static const List<int> all = [w100, w200, w300, w400, w500, w600, w700, w800];

  /// Clamps to nearest supported step (100–800).
  static int normalize(int? value, {int fallback = w400}) {
    if (value == null) {
      return fallback;
    }
    if (value <= 150) {
      return w100;
    }
    if (value <= 250) {
      return w200;
    }
    if (value <= 350) {
      return w300;
    }
    if (value <= 450) {
      return w400;
    }
    if (value <= 550) {
      return w500;
    }
    if (value <= 650) {
      return w600;
    }
    if (value <= 750) {
      return w700;
    }
    return w800;
  }

  static FontWeight toFlutter(int weight) {
    return switch (normalize(weight)) {
      w100 => FontWeight.w100,
      w200 => FontWeight.w200,
      w300 => FontWeight.w300,
      w400 => FontWeight.w400,
      w500 => FontWeight.w500,
      w600 => FontWeight.w600,
      w700 => FontWeight.w700,
      _ => FontWeight.w800,
    };
  }
}
