import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/services/secure_storage_service.dart';
import 'package:aetherssh/core/theme/app_sizes.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/widgets/pulsing_status_dot.dart';
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

  bool _useCustomAi = false;
  String _provider = 'custom';
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;
  bool? _testSuccess;

  static const _accentColor = Color(0xFF00B0FF);

  // Embedded defaults for background testing without exposing in text inputs
  static const _nvidiaDefaultEndpoint = 'https://integrate.api.nvidia.com/v1';
  static const _nvidiaDefaultModel = 'nvidia/nemotron-3.5-lightning-30b-a3b';
  static const _nvidiaEmbeddedApiKey =
      'nvapi-placeholder';

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
    final useCustom = await storage.readAiUseCustom();
    final config = await storage.readAiConfig();

    setState(() {
      _useCustomAi = useCustom;
      if (useCustom) {
        _provider = config['provider'] ?? 'custom';
        _apiKeyController.text = config['apiKey'] ?? '';
        _modelController.text = config['model'] ?? 'gpt-4o-mini';
        _endpointController.text =
            config['endpoint'] ?? 'https://api.openai.com/v1';
      } else {
        _provider = 'custom';
        _apiKeyController.clear();
        _modelController.text = 'gpt-4o-mini';
        _endpointController.text = 'https://api.openai.com/v1';
      }
    });
  }

  Future<void> _toggleCustomAi(bool enabled) async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.saveAiUseCustom(enabled);

    setState(() {
      _useCustomAi = enabled;
      _testResult = null;
      _testSuccess = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Custom AI mode enabled. Please configure your credentials.'
                : 'Switched to built-in Zor Neural Engine.',
          ),
          backgroundColor:
              enabled ? _accentColor : const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testDefaultAi() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final result = await AiService.testConnection(
      endpoint: _nvidiaDefaultEndpoint,
      apiKey: _nvidiaEmbeddedApiKey,
      model: _nvidiaDefaultModel,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result.isSuccess;
        _testResult = result.isSuccess
            ? 'Zor Neural Engine is responsive and ready.'
            : 'Connection check failed: ${result.message}';
      });
    }
  }

  Future<void> _testCustomConnection() async {
    final apiKey = _apiKeyController.text.trim();
    final endpoint = _endpointController.text.trim();
    final model = _modelController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Please enter an API Key to test custom connection';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final result = await AiService.testConnection(
      endpoint: endpoint,
      apiKey: apiKey,
      model: model,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result.isSuccess;
        _testResult = result.message;
      });
    }
  }

  Future<void> _saveCustomConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final storage = ref.read(secureStorageServiceProvider);

    await storage.saveAiConfig(
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      endpoint: _endpointController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom AI Configuration saved securely in Keystore'),
          backgroundColor: Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Revert to Built-in AI?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'This will remove your custom AI settings and immediately reactivate the built-in Zor Neural Engine.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revert to Default'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = ref.read(secureStorageServiceProvider);
      await storage.deleteAiCredentials();
      setState(() {
        _useCustomAi = false;
        _apiKeyController.clear();
        _testResult = null;
        _testSuccess = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reverted to built-in Zor Neural Engine'),
            backgroundColor: Color(0xFF00E676),
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
          'AI Assistant Settings',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Built-in AI Engine Banner ──────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'DEFAULT AI SERVICE',
                style: AppTheme.sectionTitleStyle,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF131A26),
                    _useCustomAi
                        ? const Color(0xFF0E131C)
                        : const Color(0xFF0B1917),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _useCustomAi
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFF00E676).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _useCustomAi
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFF00E676).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Zor Neural Cloud Engine',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                if (!_useCustomAi)
                                  const PulsingStatusDot(
                                    isOnline: true,
                                    size: 10,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              !_useCustomAi
                                  ? 'Active • High-Speed Terminal Intelligence'
                                  : 'Standby • Custom Provider Active',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: !_useCustomAi
                                    ? const Color(0xFF00E676)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Built-in AI provides instant natural language commands, server diagnostics, and script explanations directly inside your terminal with zero setup.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.shieldCheck,
                              size: 13,
                              color: Color(0xFF00E676),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Zero-Key Config',
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.zap,
                              size: 13,
                              color: Color(0xFF00B0FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ultra Low Latency',
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_useCustomAi) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E676),
                          side: BorderSide(
                            color: const Color(0xFF00E676).withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isTesting ? null : _testDefaultAi,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00E676),
                                ),
                              )
                            : const Icon(LucideIcons.radio, size: 15),
                        label: Text(
                          _isTesting
                              ? 'Checking AI Engine...'
                              : 'Test Built-in AI Connection',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!_useCustomAi && _testResult != null) ...[
              const SizedBox(height: 12),
              _buildTestResultBadge(),
            ],

            const SizedBox(height: 28),

            // ── Custom AI Configuration Toggle ────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'CUSTOM AI CONFIGURATION',
                style: AppTheme.sectionTitleStyle,
              ),
            ),
            SystemCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _useCustomAi
                        ? _accentColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.sliders,
                    color: _useCustomAi ? _accentColor : Colors.white60,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Use Custom AI Configuration',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _useCustomAi
                      ? 'Override default with your own model or endpoint'
                      : 'Disabled — using default Zor Neural Engine',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                value: _useCustomAi,
                activeThumbColor: _accentColor,
                activeTrackColor: _accentColor.withValues(alpha: 0.3),
                onChanged: _toggleCustomAi,
              ),
            ),

            // ── Custom Settings Form (Only shown when switch is ON) ──
            if (_useCustomAi) ...[
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider selector
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('PROVIDER', style: AppTheme.sectionTitleStyle),
                    ),
                    SystemCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(
                              'OpenAI / OpenRouter / Groq',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Official cloud LLM APIs',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: _accentColor,
                            value: 'custom',
                            groupValue: _provider,
                            onChanged: (val) {
                              setState(() {
                                _provider = val!;
                                if (_endpointController.text.contains('11434')) {
                                  _endpointController.text =
                                      'https://api.openai.com/v1';
                                  _modelController.text = 'gpt-4o-mini';
                                }
                              });
                            },
                          ),
                          const Divider(color: Colors.white10),
                          RadioListTile<String>(
                            title: Text(
                              'Self-Hosted Ollama / Local vLLM',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'e.g. http://192.168.1.50:11434/v1',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: _accentColor,
                            value: 'ollama',
                            groupValue: _provider,
                            onChanged: (val) {
                              setState(() {
                                _provider = val!;
                                _endpointController.text =
                                    'http://localhost:11434/v1';
                                _modelController.text = 'llama3.2:latest';
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Custom Credentials Card
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'CUSTOM CREDENTIALS',
                        style: AppTheme.sectionTitleStyle,
                      ),
                    ),
                    SystemCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Key',
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
                            style: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
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
                                  _obscureApiKey
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscureApiKey = !_obscureApiKey,
                                  );
                                },
                              ),
                            ),
                            validator: (val) {
                              if (_useCustomAi &&
                                  _provider != 'ollama' &&
                                  (val == null || val.trim().isEmpty)) {
                                return 'API Key is required for this provider';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Model Identifier',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _modelController,
                            style: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. gpt-4o-mini or llama3',
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
                            style: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'https://api.openai.com/v1',
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
                              if (!val.startsWith('http://') &&
                                  !val.startsWith('https://')) {
                                return 'Must start with http:// or https://';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Test Custom Connection Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accentColor,
                                side: const BorderSide(color: _accentColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed:
                                  _isTesting ? null : _testCustomConnection,
                              icon: _isTesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _accentColor,
                                      ),
                                    )
                                  : const Icon(LucideIcons.radio, size: 16),
                              label: Text(
                                _isTesting
                                    ? 'Testing Custom Endpoint...'
                                    : 'Test Custom Connection',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          if (_testResult != null) ...[
                            const SizedBox(height: 12),
                            _buildTestResultBadge(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveCustomConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(LucideIcons.check, size: 18),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Custom Configuration',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.critical,
                        ),
                        onPressed: _resetToDefault,
                        icon: const Icon(LucideIcons.rotateCcw, size: 16),
                        label: const Text('Revert to Built-in AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _testSuccess == true
            ? const Color(0xFF00E676).withValues(alpha: 0.1)
            : AppTheme.critical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _testSuccess == true
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
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
                ? const Color(0xFF00E676)
                : AppTheme.critical,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _testResult!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _testSuccess == true
                    ? const Color(0xFF00E676)
                    : AppTheme.critical,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
