import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:aetherssh/core/models/server.dart';
import 'package:aetherssh/core/providers.dart';
import 'package:aetherssh/core/services/clipboard_sync_service.dart';
import 'package:aetherssh/core/services/os_detector.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/widgets/os_icon.dart';

class ClipboardSyncSheet extends ConsumerStatefulWidget {
  final Server server;
  final SSHClient? activeClient;
  final OsInfo? osInfo;

  const ClipboardSyncSheet({
    super.key,
    required this.server,
    this.activeClient,
    this.osInfo,
  });

  static Future<void> show(
    BuildContext context, {
    required Server server,
    SSHClient? activeClient,
    OsInfo? osInfo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipboardSyncSheet(
        server: server,
        activeClient: activeClient,
        osInfo: osInfo,
      ),
    );
  }

  @override
  ConsumerState<ClipboardSyncSheet> createState() => _ClipboardSyncSheetState();
}

class _ClipboardSyncSheetState extends ConsumerState<ClipboardSyncSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _troubleshooting;
  late OsInfo _currentOs;
  SSHClient? _ownedClient;

  @override
  void initState() {
    super.initState();
    _currentOs = widget.osInfo ?? OsInfo.fromDistroString(widget.server.osDistro);
    _fetchClipboardText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ownedClient?.close();
    super.dispose();
  }

  Future<void> _fetchClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && mounted) {
        setState(() {
          _textController.text = data!.text!;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendToRemote() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste some text first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _troubleshooting = null;
    });

    SSHClient? client = widget.activeClient ?? _ownedClient;

    try {
      if (client == null) {
        final ssh = ref.read(sshServiceProvider);
        client = await ssh.connect(
          widget.server.hostname,
          widget.server.port,
          widget.server.username,
          widget.server.id,
        );
        _ownedClient = client;

        // Detect OS if unknown
        if (_currentOs.type == OsType.unknown) {
          _currentOs = await OsDetector.detect(client);
        }
      }

      final result = await ClipboardSyncService.syncToRemote(
        client: client,
        osInfo: _currentOs,
        text: _textController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: AppTheme.terminalMint, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
          _troubleshooting = result.troubleshooting;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'SSH Connection Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF131418),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.terminalMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.clipboardCopy, color: AppTheme.terminalMint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared Clipboard',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        OsIconWidget(osInfo: _currentOs, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Target: ${widget.server.name} (${_currentOs.distroName})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Text content input
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 3,
                  style: GoogleFonts.firaCode(fontSize: 13, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter or paste text to send to PC clipboard...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_textController.text.length} characters',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(LucideIcons.clipboardPaste, size: 13, color: AppTheme.terminalMint),
                        label: Text(
                          'Paste from Android',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.terminalMint),
                        ),
                        onPressed: _fetchClipboardText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error / Troubleshooting banner if present
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_troubleshooting != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _troubleshooting!,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Send button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendToRemote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terminalMint,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.terminalMint.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Send to PC Clipboard',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
