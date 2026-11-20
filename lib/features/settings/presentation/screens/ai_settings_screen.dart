import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/services/secure_storage_service.dart';
import 'package:aetherssh/core/theme/app_sizes.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/widgets/system_card.dart';
import 'package:aetherssh/features/terminal/services/ai_service.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _endpointController = TextEditingController();

  String _provider = 'nvidia';
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;
  bool? _testSuccess;

  static const _nvidiaDefaultEndpoint = 'https://integrate.api.nvidia.com/v1';
  static const _nvidiaDefaultModel = 'meta/llama-3.1-70b-instruct';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final storage = ref.read(secureStorageServiceProvider);
    final config = await storage.readAiConfig();

    setState(() {
      _provider = config['provider'] ?? 'nvidia';
      _apiKeyController.text = config['apiKey'] ?? '';
      _modelController.text = config['model'] ?? _nvidiaDefaultModel;
      _endpointController.text = config['endpoint'] ?? _nvidiaDefaultEndpoint;
    });
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    final endpoint = _endpointController.text.trim();
    final model = _modelController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Please enter an API Key to test connection';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final result = await AiService.testConnection(
      endpoint: endpoint.isNotEmpty ? endpoint : _nvidiaDefaultEndpoint,
      apiKey: apiKey,
      model: model.isNotEmpty ? model : _nvidiaDefaultModel,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result.isSuccess;
        _testResult = result.message;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final storage = ref.read(secureStorageServiceProvider);

    await storage.saveAiConfig(
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : _nvidiaDefaultModel,
      endpoint: _endpointController.text.trim().isNotEmpty
          ? _endpointController.text.trim()
          : _nvidiaDefaultEndpoint,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Configuration saved securely in Keystore'),
          backgroundColor: AppTheme.terminalMint,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete AI Credentials?'),
        content: const Text(
          'This will remove your stored API Key, Model, and Endpoint from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = ref.read(secureStorageServiceProvider);
      await storage.deleteAiCredentials();
      setState(() {
        _apiKeyController.clear();
        _modelController.text = _nvidiaDefaultModel;
        _endpointController.text = _nvidiaDefaultEndpoint;
        _provider = 'nvidia';
        _testResult = null;
        _testSuccess = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Credentials deleted'),
            backgroundColor: AppTheme.critical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'AI Provider Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Selector Card
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('AI PROVIDER', style: AppTheme.sectionTitleStyle),
              ),
              SystemCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        'NVIDIA NIM (Recommended)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Official NVIDIA API endpoint & enterprise AI models',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      activeColor: const Color(0xFF76B900), // NVIDIA Green
                      value: 'nvidia',
                      groupValue: _provider,
                      onChanged: (val) {
                        setState(() {
                          _provider = val!;
                          _endpointController.text = _nvidiaDefaultEndpoint;
                          _modelController.text = _nvidiaDefaultModel;
                        });
                      },
                    ),
                    const Divider(color: Colors.white10),
                    RadioListTile<String>(
                      title: Text(
                        'Custom OpenAI-Compatible Endpoint',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Self-hosted Ollama, vLLM, OpenAI, Groq, or OpenRouter',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      activeColor: AppTheme.terminalMint,
                      value: 'custom',
                      groupValue: _provider,
                      onChanged: (val) {
                        setState(() => _provider = val!);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Credentials & Config Card
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('CONFIGURATION', style: AppTheme.sectionTitleStyle),
              ),
              SystemCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Key
                    Text(
                      _provider == 'nvidia' ? 'NVIDIA API Key' : 'API Key',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      style: GoogleFonts.firaCode(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _provider == 'nvidia'
                            ? 'nvapi-xxxxxxxxxxxxxxxxxxxxxxxx'
                            : 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
                        hintStyle: GoogleFonts.firaCode(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscureApiKey = !_obscureApiKey);
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'API Key is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Model Name
                    Text(
                      'Model Name',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _modelController,
                      style: GoogleFonts.firaCode(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. meta/llama-3.1-70b-instruct',
                        hintStyle: GoogleFonts.firaCode(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Model name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // API Endpoint URL
                    Text(
                      'API Endpoint Base URL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _endpointController,
                      style: GoogleFonts.firaCode(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'https://integrate.api.nvidia.com/v1',
                        hintStyle: GoogleFonts.firaCode(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Endpoint URL is required';
                        }
                        if (!val.startsWith('http://') && !val.startsWith('https://')) {
                          return 'Must start with http:// or https://';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Test Connection Button & Result
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.terminalMint,
                          side: const BorderSide(color: AppTheme.terminalMint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.terminalMint,
                                ),
                              )
                            : const Icon(LucideIcons.radio, size: 16),
                        label: Text(
                          _isTesting ? 'Testing Connection...' : 'Test Connection',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testSuccess == true
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.critical.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testSuccess == true
                                ? AppTheme.success.withValues(alpha: 0.3)
                                : AppTheme.critical.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _testSuccess == true
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.alertCircle,
                              size: 16,
                              color: _testSuccess == true
                                  ? AppTheme.success
                                  : AppTheme.critical,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResult!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _testSuccess == true
                                      ? AppTheme.success
                                      : AppTheme.critical,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terminalMint,
                    foregroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(LucideIcons.check, size: 20),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Configuration',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Delete Credentials Button
              if (_apiKeyController.text.isNotEmpty)
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.critical,
                    ),
                    onPressed: _deleteCredentials,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Delete Stored AI Credentials'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
