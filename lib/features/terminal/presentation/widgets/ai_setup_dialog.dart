import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zorssh/core/services/secure_storage_service.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/features/terminal/services/ai_service.dart';

class AiSetupDialog extends ConsumerStatefulWidget {
  const AiSetupDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AiSetupDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AiSetupDialog> createState() => _AiSetupDialogState();
}

class _AiSetupDialogState extends ConsumerState<AiSetupDialog> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(
    text: 'meta/llama-3.1-70b-instruct',
  );
  final _endpointController = TextEditingController(
    text: 'https://integrate.api.nvidia.com/v1',
  );

  bool _obscureKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testStatus;
  bool? _testSuccess;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testStatus = 'Please enter your NVIDIA API key';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testStatus = null;
      _testSuccess = null;
    });

    final res = await AiService.testConnection(
      endpoint: _endpointController.text.trim(),
      apiKey: key,
      model: _modelController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = res.isSuccess;
        _testStatus = res.message;
      });
    }
  }

  Future<void> _save() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testStatus = 'API Key is required';
      });
      return;
    }

    setState(() => _isSaving = true);
    final storage = ref.read(secureStorageServiceProvider);
    await storage.saveAiConfig(
      provider: 'nvidia',
      apiKey: key,
      model: _modelController.text.trim(),
      endpoint: _endpointController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141518),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF76B900).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF76B900).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Color(0xFF76B900),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Provider Setup',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'NVIDIA NIM AI Integration',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF76B900),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your NVIDIA API Key to enable AI-powered terminal command generation. Credentials are stored securely on your device using Android Keystore.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // API Key
            Text(
              'NVIDIA API Key',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'nvapi-xxxxxxxxxxxxxxxxxxxxxxxx',
                hintStyle: GoogleFonts.firaCode(color: Colors.white30, fontSize: 12),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Model
            Text(
              'NVIDIA Model Name',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _modelController,
              style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Endpoint
            Text(
              'API Endpoint',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _endpointController,
              style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF76B900),
                  side: const BorderSide(color: Color(0xFF76B900)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF76B900),
                        ),
                      )
                    : const Icon(LucideIcons.radio, size: 14),
                label: Text(
                  _isTesting ? 'Testing...' : 'Test Connection',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_testStatus != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess == true
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.critical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? LucideIcons.check : LucideIcons.alertCircle,
                      size: 14,
                      color: _testSuccess == true ? AppTheme.success : AppTheme.critical,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testStatus!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _testSuccess == true ? AppTheme.success : AppTheme.critical,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF76B900),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save & Enable AI',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
