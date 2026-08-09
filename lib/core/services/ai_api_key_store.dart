import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AiCloudProvider {
  openai,
  gemini;

  String get storageValue => name;

  static AiCloudProvider? tryParse(String? raw) {
    switch (raw) {
      case 'openai':
        return AiCloudProvider.openai;
      case 'gemini':
        return AiCloudProvider.gemini;
      default:
        return null;
    }
  }

  String get label => switch (this) {
    AiCloudProvider.openai => 'OpenAI',
    AiCloudProvider.gemini => 'Gemini',
  };

  String get defaultModel => switch (this) {
    AiCloudProvider.openai => 'gpt-4o-mini',
    AiCloudProvider.gemini => 'gemini-2.0-flash',
  };
}

@immutable
class AiApiKeyConfig {
  const AiApiKeyConfig({
    this.provider,
    this.apiKey = '',
    this.model = '',
  });

  const AiApiKeyConfig.empty()
    : provider = null,
      apiKey = '',
      model = '';

  final AiCloudProvider? provider;
  final String apiKey;
  final String model;

  bool get hasKey =>
      provider != null && apiKey.trim().isNotEmpty;

  String get effectiveModel {
    final trimmed = model.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return provider?.defaultModel ?? '';
  }

  String get maskedApiKey {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return '';
    }
    if (key.length <= 8) {
      return '••••••••';
    }
    return '${key.substring(0, 3)}••••${key.substring(key.length - 4)}';
  }

  AiApiKeyConfig copyWith({
    AiCloudProvider? provider,
    String? apiKey,
    String? model,
    bool clearProvider = false,
  }) {
    return AiApiKeyConfig(
      provider: clearProvider ? null : (provider ?? this.provider),
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

/// Persists the user's BYOK cloud AI credentials.
class AiApiKeyStore extends ChangeNotifier {
  AiApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// In-memory store for widget/unit tests (no secure storage plugin).
  factory AiApiKeyStore.inMemory([AiApiKeyConfig? initial]) {
    return _InMemoryAiApiKeyStore(initial ?? const AiApiKeyConfig.empty());
  }

  static const _providerKey = 'ai_cloud_provider';
  static const _apiKeyKey = 'ai_cloud_api_key';
  static const _modelKey = 'ai_cloud_model';

  final FlutterSecureStorage _storage;
  AiApiKeyConfig _config = const AiApiKeyConfig.empty();
  bool _loaded = false;

  AiApiKeyConfig get config => _config;
  bool get isLoaded => _loaded;
  bool get hasKey => _config.hasKey;

  Future<void> load() async {
    try {
      final providerRaw = await _storage.read(key: _providerKey);
      final apiKey = await _storage.read(key: _apiKeyKey) ?? '';
      final model = await _storage.read(key: _modelKey) ?? '';
      _config = AiApiKeyConfig(
        provider: AiCloudProvider.tryParse(providerRaw),
        apiKey: apiKey,
        model: model,
      );
    } catch (_) {
      _config = const AiApiKeyConfig.empty();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({
    required AiCloudProvider provider,
    required String apiKey,
    String model = '',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw ArgumentError('API key cannot be empty.');
    }
    final trimmedModel = model.trim();
    await _storage.write(key: _providerKey, value: provider.storageValue);
    await _storage.write(key: _apiKeyKey, value: trimmedKey);
    await _storage.write(key: _modelKey, value: trimmedModel);
    _config = AiApiKeyConfig(
      provider: provider,
      apiKey: trimmedKey,
      model: trimmedModel,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> clear() async {
    await _storage.delete(key: _providerKey);
    await _storage.delete(key: _apiKeyKey);
    await _storage.delete(key: _modelKey);
    _config = const AiApiKeyConfig.empty();
    _loaded = true;
    notifyListeners();
  }
}

class _InMemoryAiApiKeyStore extends AiApiKeyStore {
  _InMemoryAiApiKeyStore(AiApiKeyConfig initial)
    : super(storage: const FlutterSecureStorage()) {
    _memory = initial;
    _memoryLoaded = true;
  }

  late AiApiKeyConfig _memory;
  bool _memoryLoaded = false;

  @override
  AiApiKeyConfig get config => _memory;

  @override
  bool get isLoaded => _memoryLoaded;

  @override
  bool get hasKey => _memory.hasKey;

  @override
  Future<void> load() async {
    _memoryLoaded = true;
    notifyListeners();
  }

  @override
  Future<void> save({
    required AiCloudProvider provider,
    required String apiKey,
    String model = '',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw ArgumentError('API key cannot be empty.');
    }
    _memory = AiApiKeyConfig(
      provider: provider,
      apiKey: trimmedKey,
      model: model.trim(),
    );
    _memoryLoaded = true;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    _memory = const AiApiKeyConfig.empty();
    _memoryLoaded = true;
    notifyListeners();
  }
}
