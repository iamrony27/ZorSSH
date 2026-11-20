import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/models/server.dart';
import 'package:aetherssh/core/services/os_detector.dart';
import 'package:aetherssh/core/services/secure_storage_service.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/widgets/os_icon.dart';
import 'package:aetherssh/features/terminal/presentation/widgets/ai_setup_dialog.dart';
import 'package:aetherssh/features/terminal/services/ai_service.dart';

class AiCommandSheet extends ConsumerStatefulWidget {
  final Server server;
  final ValueChanged<String> onExecuteCommand;

  const AiCommandSheet({
    super.key,
    required this.server,
    required this.onExecuteCommand,
  });

  static void show(
    BuildContext context, {
    required Server server,
    required ValueChanged<String> onExecuteCommand,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141518),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AiCommandSheet(
        server: server,
        onExecuteCommand: onExecuteCommand,
      ),
    );
  }

  @override
  ConsumerState<AiCommandSheet> createState() => _AiCommandSheetState();
}

class _AiCommandSheetState extends ConsumerState<AiCommandSheet> {
  final _inputController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedCommand;
  String? _errorMessage;

  static const List<String> _quickPrompts = [
    'Turn off PC',
    'Restart computer',
    'Check RAM usage',
    'Show running processes',
    'Find large files over 100MB',
    'Check disk space',
    'Show active services',
    'Restart Docker',
    'Check IP address',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _generateCommand([String? overridePrompt]) async {
    final prompt = (overridePrompt ?? _inputController.text).trim();
    if (prompt.isEmpty) return;

    if (overridePrompt != null) {
      _inputController.text = overridePrompt;
    }

    final storage = ref.read(secureStorageServiceProvider);
    final aiConfig = await storage.readAiConfig();

    if (aiConfig['apiKey'] == null || aiConfig['apiKey']!.isEmpty) {
      if (!mounted) return;
      final configured = await AiSetupDialog.show(context);
      if (!configured || !mounted) return;
      return _generateCommand(prompt);
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedCommand = null;
    });

    try {
      final osInfo = OsInfo.fromDistroString(widget.server.osDistro);

      final command = await AiService.generateCommand(
        userPrompt: prompt,
        osInfo: osInfo,
        endpoint: aiConfig['endpoint']!,
        apiKey: aiConfig['apiKey']!,
        model: aiConfig['model']!,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatedCommand = command;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _confirmAndExecute(String command) async {
    final safety = AiService.assessSafety(command);

    if (safety.isDangerous) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.critical, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppTheme.critical, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Dangerous Action',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safety.warningMessage ?? 'This operation may affect system availability or delete data.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  command,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: AppTheme.critical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.critical,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Execute Command'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onExecuteCommand(command);
    }
  }

  @override
  Widget build(BuildContext context) {
    final osInfo = OsInfo.fromDistroString(widget.server.osDistro);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header with target OS badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.terminalMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: AppTheme.terminalMint,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Commands',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          OsIconWidget(osDistro: widget.server.osDistro, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '${osInfo.distroName} • ${osInfo.shell}',
                            style: GoogleFonts.firaCode(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Prompt suggestions
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (context, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _generateCommand(prompt),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _generateCommand(),
                    decoration: InputDecoration(
                      hintText: 'Describe an operation in plain English...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: Colors.black38,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.terminalMint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.terminalMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            LucideIcons.arrowUp,
                            color: Colors.black,
                            size: 20,
                          ),
                    onPressed: _isGenerating ? null : () => _generateCommand(),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.critical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.critical.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 16, color: AppTheme.critical),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.critical),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_generatedCommand != null) ...[
              const SizedBox(height: 16),
              // Dedicated Command Card with RUN button
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0E11),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.terminalMint.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.terminalMint.withValues(alpha: 0.08),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GENERATED COMMAND',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppTheme.terminalMint,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.copy, size: 15, color: Colors.white70),
                          tooltip: 'Copy command',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedCommand!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Command copied to clipboard'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _generatedCommand!,
                      style: GoogleFonts.firaCode(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.terminalMint,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _confirmAndExecute(_generatedCommand!),
                        icon: const Icon(LucideIcons.play, size: 16, color: Colors.black),
                        label: Text(
                          'RUN COMMAND',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
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
    );
  }
}
