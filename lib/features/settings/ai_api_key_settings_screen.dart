import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/services/ai_api_key_store.dart';
import '../../core/services/cloud_ai_resume_service.dart';

class AiApiKeySettingsScreen extends StatefulWidget {
  const AiApiKeySettingsScreen({super.key});

  @override
  State<AiApiKeySettingsScreen> createState() => _AiApiKeySettingsScreenState();
}

class _AiApiKeySettingsScreenState extends State<AiApiKeySettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  AiCloudProvider _provider = AiCloudProvider.openai;
  bool _obscureKey = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromStore());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromStore() async {
    final store = context.read<AiApiKeyStore>();
    if (!store.isLoaded) {
      await store.load();
    }
    if (!mounted) {
      return;
    }
    final config = store.config;
    setState(() {
      _provider = config.provider ?? AiCloudProvider.openai;
      _apiKeyController.text = config.apiKey;
      _modelController.text = config.model;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiApiKeyRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AiApiKeyStore>().save(
        provider: _provider,
        apiKey: key,
        model: _modelController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiApiKeySaved)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _clear() async {
    setState(() => _isClearing = true);
    try {
      await context.read<AiApiKeyStore>().clear();
      if (!mounted) {
        return;
      }
      setState(() {
        _apiKeyController.clear();
        _modelController.clear();
        _provider = AiCloudProvider.openai;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aiApiKeyRemoved)),
      );
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _testConnection() async {
    final l10n = context.l10n;
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiApiKeyRequired)),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final cloud = context.read<CloudAiResumeService>();
      await cloud.testConnection(
        AiApiKeyConfig(
          provider: _provider,
          apiKey: key,
          model: _modelController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiApiKeyTestSuccess)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final store = context.watch<AiApiKeyStore>();
    final busy = _isSaving || _isTesting || _isClearing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiApiKeySettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            l10n.aiApiKeySettingsIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.aiProviderLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AiCloudProvider>(
            key: ValueKey('ai-provider-dropdown-$_provider'),
            initialValue: _provider,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: [
              for (final provider in AiCloudProvider.values)
                DropdownMenuItem(
                  value: provider,
                  child: Text(provider.label),
                ),
            ],
            onChanged: busy
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _provider = value;
                      if (_modelController.text.trim().isEmpty ||
                          _modelController.text.trim() ==
                              AiCloudProvider.openai.defaultModel ||
                          _modelController.text.trim() ==
                              AiCloudProvider.gemini.defaultModel) {
                        _modelController.text = value.defaultModel;
                      }
                    });
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('ai-api-key-field'),
            controller: _apiKeyController,
            obscureText: _obscureKey,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: l10n.aiApiKeyLabel,
              hintText: l10n.aiApiKeyHint,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('ai-model-field'),
            controller: _modelController,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: l10n.aiModelOptionalLabel,
              hintText: _provider.defaultModel,
            ),
          ),
          if (store.hasKey) ...[
            const SizedBox(height: 12),
            Text(
              l10n.aiApiKeySavedMasked(store.config.maskedApiKey),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('ai-api-key-save-button'),
            onPressed: busy ? null : _save,
            child: Text(l10n.saveAiApiKey),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('ai-api-key-test-button'),
            onPressed: busy ? null : _testConnection,
            child: Text(l10n.testAiApiKey),
          ),
          const SizedBox(height: 10),
          TextButton(
            key: const Key('ai-api-key-remove-button'),
            onPressed: busy || !store.hasKey ? null : _clear,
            child: Text(l10n.removeAiApiKey),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
