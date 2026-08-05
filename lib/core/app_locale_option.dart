import 'package:flutter/material.dart';

/// Supported app UI languages (resume content is never translated by this).
abstract final class AppLocaleOption {
  static const system = 'system';
  static const english = 'en';
  static const spanish = 'es';
  static const portugueseBrazil = 'pt';
  static const indonesian = 'id';

  static const supportedPreferenceCodes = <String>[
    system,
    english,
    spanish,
    portugueseBrazil,
    indonesian,
  ];

  /// Locale forced on [MaterialApp], or `null` to follow the device.
  static Locale? materialLocaleFor(String preferenceCode) {
    return switch (preferenceCode) {
      english => const Locale('en'),
      spanish => const Locale('es'),
      portugueseBrazil => const Locale('pt'),
      indonesian => const Locale('id'),
      _ => null,
    };
  }

  static String normalizePreference(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value == system) {
      return system;
    }
    if (supportedPreferenceCodes.contains(value)) {
      return value;
    }
    return system;
  }
}
