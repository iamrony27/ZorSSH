import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/models/server.dart';
import 'package:aetherssh/core/providers.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/theme/app_sizes.dart';
import 'package:aetherssh/core/localization/app_localization.dart';
import 'package:aetherssh/core/utils/error_mapper.dart';
import 'package:aetherssh/core/widgets/os_icon.dart';
import 'package:aetherssh/features/terminal/presentation/widgets/ai_command_sheet.dart';
import 'package:aetherssh/features/terminal/providers/terminal_provider.dart';
import 'package:xterm/xterm.dart' hide TerminalState;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _terminalController = TerminalController();
  final _terminalScrollController = ScrollController();
  final _terminalFocusNode = FocusNode();
  bool _ctrlActive = false;
  bool _altActive = false;
  double _lastBottomInset = 0;

  void _ensureTerminalFocus() {
    if (!_terminalFocusNode.hasFocus) {
      _terminalFocusNode.requestFocus();
    }
  }

  Future<void> _handleCopy() async {
    final selection = _terminalController.selection;
    final terminal = ref.read(terminalProvider).terminal;
    String text = '';
    if (selection != null) {
      text = terminal.buffer.getText(selection);
    } else {
      final buffer = terminal.buffer;
      final lines = <String>[];
      for (int i = 0; i < buffer.lines.length; i++) {
        final lineStr = buffer.lines[i].getText().trimRight();
        if (lineStr.isNotEmpty) lines.add(lineStr);
      }
      text = lines.join('\n');
    }
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selection != null
                ? 'Copied selection to clipboard'
                : 'Copied terminal output to clipboard'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleCut() async {
    final selection = _terminalController.selection;
    final terminal = ref.read(terminalProvider).terminal;
    if (selection != null) {
      final text = terminal.buffer.getText(selection);
      await Clipboard.setData(ClipboardData(text: text));
      _terminalController.clearSelection();
      ref.read(terminalProvider.notifier).sendRaw('\x15');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cut selection to clipboard'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      final terminal = ref.read(terminalProvider).terminal;
      terminal.paste(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasted ${text.length > 25 ? '${text.substring(0, 25)}...' : text}'),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _processTerminalInput(String data) {
    if (data.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTerminalToBottom());
    String processed = data;
    if (_ctrlActive || _altActive) {
      final buffer = StringBuffer();
      for (int i = 0; i < data.length; i++) {
        final code = data.codeUnitAt(i);
        String char = data[i];
        if (_ctrlActive) {
          // Convert ASCII '@' through '_' and 'a' through 'z' to control bytes 0x00..0x1F [UI-001]
          if ((code >= 64 && code <= 95) || (code >= 97 && code <= 122)) {
            char = String.fromCharCode(code & 0x1F);
          }
        }
        if (_altActive) {
          char = '\x1b$char';
        }
        buffer.write(char);
      }
      processed = buffer.toString();
      setState(() {
        _ctrlActive = false;
        _altActive = false;
      });
    }
    ref.read(terminalProvider.notifier).sendRaw(processed);
  }

  Terminal? _attachedTerminal;

  void _attachTerminal(Terminal terminal) {
    if (_attachedTerminal == terminal &&
        terminal.onOutput == _processTerminalInput) {
      return;
    }
    _attachedTerminal = terminal;
    terminal.onOutput = _processTerminalInput;
  }

  void _openAiCommands(Server? server) {
    if (server == null) return;
    AiCommandSheet.show(
      context,
      server: server,
      onExecuteCommand: (command) {
        ref.read(terminalProvider.notifier).sendRaw('$command\n');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // [UI-001]: Attach input interceptor once during initialization rather than inside build()
    _attachTerminal(ref.read(terminalProvider).terminal);
    ref.listenManual(terminalProvider, (previous, next) {
      if (previous?.terminal != next.terminal) {
        _attachTerminal(next.terminal);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = GoRouterState.of(context).extra;
        if (args is Server) {
          ref.read(terminalProvider.notifier).connectToServer(args);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _terminalScrollController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  void _scrollTerminalToBottom() {
    if (!_terminalScrollController.hasClients) return;
    final pos = _terminalScrollController.position;
    _terminalScrollController.jumpTo(pos.maxScrollExtent);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(terminalProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset != _lastBottomInset) {
      _lastBottomInset = bottomInset;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTerminalToBottom());
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(state),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (state.status) {
          TerminalStatus.idle => _buildServerSelector(),
          TerminalStatus.connecting => _buildOverlay(
            key: const ValueKey('connecting'),
          ),
          TerminalStatus.connected => _buildTerminalView(state),
          TerminalStatus.disconnecting => _buildOverlay(
            key: const ValueKey('disconnecting'),
            label: 'Disconnecting…',
          ),
          TerminalStatus.error => _buildErrorView(state),
        },
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(TerminalState state) {
    final server = state.selectedServer;

    Widget titleWidget;
    if (server != null && state.status != TerminalStatus.idle) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.terminal,
            size: 18,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: AppSizes.p8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  server.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${server.username}@${server.hostname}',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      titleWidget = Text(
        ref.tr('nav_terminal'),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: titleWidget,
      actions: [
        if (state.isConnected) ...[
          // Connected indicator dot
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.p4),
            child: Container(
              width: AppSizes.p8,
              height: AppSizes.p8,
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // AI Commands
          IconButton(
            icon: const Icon(LucideIcons.sparkles, size: 18),
            color: const Color(0xFF76B900),
            tooltip: 'AI Commands',
            onPressed: () => _openAiCommands(state.selectedServer),
          ),

          // Clear output
          IconButton(
            icon: const Icon(LucideIcons.eraser, size: 18),
            color: AppTheme.textPrimary,
            tooltip: 'Clear output',
            onPressed: () => ref.read(terminalProvider.notifier).clearOutput(),
          ),
          // Disconnect
          IconButton(
            icon: const Icon(LucideIcons.plugZap, size: 18),
            color: AppTheme.textPrimary,
            tooltip: 'Disconnect',
            onPressed: () => ref.read(terminalProvider.notifier).disconnect(),
          ),
        ],
        if (state.status == TerminalStatus.error)
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18),
            color: AppTheme.textSecondary,
            onPressed: () => ref.read(terminalProvider.notifier).disconnect(),
          ),
      ],
    );
  }

  // ─── Server Selector ──────────────────────────────────────────────────────

  Widget _buildServerSelector() {
    final serverListAsync = ref.watch(serverListStreamProvider);

    return serverListAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          ErrorMapper.userFriendlyMessage(e),
          style: const TextStyle(color: AppTheme.critical),
          textAlign: TextAlign.center,
        ),
      ),
      data: (servers) {
        if (servers.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.terminal,
                        size: 52,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p28),
                  Text(
                    ref.tr('no_servers_yet'),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p10),
                  Text(
                    ref.tr('add_server_prompt_terminal'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Select a system to initiate a secure shell (SSH) session and manage your server via the command line.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            Text('AVAILABLE SESSIONS', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 12),
            ...List.generate(servers.length, (index) {
              final server = servers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSessionCard(
                  server: server,
                  onTap: () => ref
                      .read(terminalProvider.notifier)
                      .connectToServer(server),
                ),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard({
    required Server server,
    required VoidCallback onTap,
  }) {
    final isOnline = server.status == ServerStatus.online;
    final statusColor = isOnline
        ? AppTheme.terminalMint
        : const Color(0xFF7E8492);
    final statusBgColor = isOnline
        ? AppTheme.terminalMint.withValues(alpha: 0.12)
        : const Color(0xFF7E8492).withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Leading icon tile
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOnline
                    ? AppTheme.terminalMint.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOnline
                      ? AppTheme.terminalMint.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: server.osDistro.isNotEmpty
                  ? Center(
                      child: OsIconWidget(
                        osDistro: server.osDistro,
                        size: 22,
                      ),
                    )
                  : Icon(
                      LucideIcons.terminal,
                      size: 20,
                      color: isOnline
                          ? AppTheme.terminalMint
                          : AppTheme.textSecondary,
                    ),
            ),
            const SizedBox(width: 14),
            // Server name & technical subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    server.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${server.username}@${server.hostname}:${server.port}',
                    style: GoogleFonts.firaCode(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Pill status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Connecting / Disconnecting Overlay ───────────────────────────────────

  Widget _buildOverlay({required Key key, String label = 'Connecting…'}) {
    return BackdropFilter(
      key: key,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: AppTheme.background.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error View ───────────────────────────────────────────────────────────

  Widget _buildErrorView(TerminalState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.critical.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.critical.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                LucideIcons.wifiOff,
                size: 32,
                color: AppTheme.critical,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Failed',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Error box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.critical.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.critical.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 16,
                    color: AppTheme.critical,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ErrorMapper.userFriendlyMessage(state.errorMessage),
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: AppTheme.critical,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(terminalProvider.notifier).disconnect(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final server = state.selectedServer;
                    if (server != null) {
                      ref
                          .read(terminalProvider.notifier)
                          .connectToServer(server);
                    }
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Terminal View ────────────────────────────────────────────────────────

  Widget _buildTerminalView(TerminalState state) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    return Column(
      children: [
        _TerminalStatusBar(
          server: state.selectedServer,
          onDisconnect: () => ref.read(terminalProvider.notifier).disconnect(),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: _TerminalWatermark(osDistro: state.selectedServer?.osDistro ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TerminalView(
                  state.terminal,
                  controller: _terminalController,
                  scrollController: _terminalScrollController,
                  focusNode: _terminalFocusNode,
                  autofocus: true,
                  onSecondaryTapDown: (details, offset) async {
                    final selection = _terminalController.selection;
                    if (selection != null) {
                      await _handleCopy();
                      _terminalController.clearSelection();
                    } else {
                      await _handlePaste();
                    }
                  },
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  textStyle: TerminalStyle(
                    fontFamily: GoogleFonts.firaCode().fontFamily!,
                    fontSize: 13,
                  ),
                  theme: _getTerminalTheme(),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: keyboardOpen
              ? Padding(
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: _QuickKeysBar(
                      terminal: state.terminal,
                      isCtrlActive: _ctrlActive,
                      isAltActive: _altActive,
                      onCtrlToggle: () {
                        setState(() {
                          _ctrlActive = !_ctrlActive;
                        });
                      },
                      onAltToggle: () {
                        setState(() {
                          _altActive = !_altActive;
                        });
                      },
                      onKeyPress: _processTerminalInput,
                      onAiCommands: () => _openAiCommands(state.selectedServer),
                      onCopy: _handleCopy,
                      onCut: _handleCut,
                      onPaste: _handlePaste,
                      onEnsureFocus: _ensureTerminalFocus,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  TerminalTheme _getTerminalTheme() {
    return TerminalTheme(
      cursor: AppTheme.primary,
      selection: AppTheme.primary.withValues(alpha: 0.3),
      foreground: AppTheme.textPrimary,
      background: Colors.transparent,
      black: Colors.black,
      red: AppTheme.critical,
      green: AppTheme.success,
      yellow: AppTheme.warning,
      blue: Colors.blue,
      magenta: Colors.pink,
      cyan: Colors.cyan,
      white: Colors.white,
      brightBlack: Colors.grey,
      brightRed: AppTheme.critical,
      brightGreen: AppTheme.success,
      brightYellow: AppTheme.warning,
      brightBlue: Colors.blueAccent,
      brightMagenta: Colors.pinkAccent,
      brightCyan: Colors.cyanAccent,
      brightWhite: Colors.white,
      searchHitBackground: AppTheme.warning.withValues(alpha: 0.5),
      searchHitBackgroundCurrent: AppTheme.warning,
      searchHitForeground: Colors.black,
    );
  }
}

class _TerminalStatusBar extends StatelessWidget {
  const _TerminalStatusBar({required this.server, this.onDisconnect});

  final Server? server;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (server == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withValues(alpha: 0.4),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SSH',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${server!.username}@${server!.hostname}:${server!.port}',
              style: GoogleFonts.firaCode(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'xterm-256color',
            style: GoogleFonts.firaCode(fontSize: 10, color: AppTheme.disabled),
          ),
          if (onDisconnect != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                LucideIcons.power,
                size: 16,
                color: AppTheme.critical,
              ),
              tooltip: 'Disconnect',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDisconnect,
            ),
          ],
        ],
      ),
    );
  }
}

class _TerminalWatermark extends StatelessWidget {
  const _TerminalWatermark({this.osDistro = ''});

  final String osDistro;

  static const _zorLogoAsset = 'assets/images/zor-logo.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final centerSize = (w * 0.38).clamp(120.0, 240.0);
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        const Color(0xFF00E676).withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Background repeating watermark pattern
              ..._buildTiles(w, h),
              // Centered prominent watermark logo
              Positioned(
                left: (w - centerSize) / 2,
                top: (h - centerSize) / 2 - 16,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    _zorLogoAsset,
                    width: centerSize,
                    height: centerSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              if (osDistro.isNotEmpty)
                Positioned(
                  right: 14,
                  bottom: 10,
                  child: Opacity(
                    opacity: 0.12,
                    child: OsIconWidget(osDistro: osDistro, size: 28),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTiles(double w, double h) {
    final widgets = <Widget>[];
    const tileW = 140.0;
    const tileH = 110.0;
    int i = 0;
    for (double y = -20; y < h + tileH; y += tileH) {
      for (double x = -20; x < w + tileW; x += tileW) {
        final dx = i.isEven ? 16.0 : -4.0;
        final dy = i % 3 == 0 ? 8.0 : -6.0;
        widgets.add(
          Positioned(
            left: x + dx,
            top: y + dy,
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                _zorLogoAsset,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        i++;
      }
    }
    return widgets;
  }
}

class _QuickKeysBar extends StatelessWidget {
  const _QuickKeysBar({
    required this.terminal,
    required this.isCtrlActive,
    required this.isAltActive,
    required this.onCtrlToggle,
    required this.onAltToggle,
    required this.onKeyPress,
    required this.onAiCommands,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    required this.onEnsureFocus,
  });

  final Terminal terminal;
  final bool isCtrlActive;
  final bool isAltActive;
  final VoidCallback onCtrlToggle;
  final VoidCallback onAltToggle;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onAiCommands;
  final VoidCallback onCopy;
  final VoidCallback onCut;
  final VoidCallback onPaste;
  final VoidCallback onEnsureFocus;

  @override
  Widget build(BuildContext context) {
    final keys = <(String, dynamic)>[
      ('PASTE', 'action_paste'),
      ('COPY', 'action_copy'),
      ('CUT', 'action_cut'),
      ('ESC', TerminalKey.escape),
      ('TAB', TerminalKey.tab),
      ('CTRL', 'ctrl'),
      ('ALT', 'alt'),
      ('^C', '\x03'),
      ('^D', '\x04'),
      ('^Z', '\x1a'),
      ('↑', TerminalKey.arrowUp),
      ('↓', TerminalKey.arrowDown),
      ('←', TerminalKey.arrowLeft),
      ('→', TerminalKey.arrowRight),
      ('/', '/'),
      ('-', '-'),
      ('|', '|'),
      ('~', '~'),
      ('HOME', TerminalKey.home),
      ('END', TerminalKey.end),
      ('PGUP', TerminalKey.pageUp),
      ('PGDN', TerminalKey.pageDown),
    ];

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Dedicated AI Commands button
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  focusNode:
                      FocusNode(canRequestFocus: false, skipTraversal: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF76B900).withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFF76B900),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFF76B900),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    onEnsureFocus();
                    onAiCommands();
                  },
                  icon: const Icon(LucideIcons.sparkles, size: 14),
                  label: Text(
                    'AI Commands',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          ...keys.map((key) {
            final action = key.$2;
            final isCtrl = key.$1 == 'CTRL';
            final isAlt = key.$1 == 'ALT';
            final isKeyActive =
                (isCtrl && isCtrlActive) || (isAlt && isAltActive);
            final isModifier =
                key.$1 == 'ESC' || key.$1 == 'TAB' || isCtrl || isAlt;
            final isClipboardAction = action == 'action_paste' ||
                action == 'action_copy' ||
                action == 'action_cut';

            Color backgroundColor;
            Color foregroundColor;
            Color borderColor;

            if (isKeyActive) {
              backgroundColor = AppTheme.terminalMint;
              foregroundColor = const Color(0xFF111318);
              borderColor = AppTheme.terminalMint;
            } else if (isClipboardAction) {
              backgroundColor = AppTheme.primary.withValues(alpha: 0.15);
              foregroundColor = AppTheme.primary;
              borderColor = AppTheme.primary.withValues(alpha: 0.35);
            } else if (isModifier) {
              backgroundColor = AppTheme.terminalMint.withValues(alpha: 0.12);
              foregroundColor = AppTheme.terminalMint;
              borderColor = AppTheme.terminalMint.withValues(alpha: 0.3);
            } else {
              backgroundColor = const Color(0xFF181A20);
              foregroundColor = AppTheme.textPrimary;
              borderColor = Colors.white.withValues(alpha: 0.08);
            }

            Widget labelWidget;
            if (action == 'action_paste') {
              labelWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.clipboardPaste, size: 13, color: foregroundColor),
                  const SizedBox(width: 4),
                  Text('PASTE',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor)),
                ],
              );
            } else if (action == 'action_copy') {
              labelWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.copy, size: 13, color: foregroundColor),
                  const SizedBox(width: 4),
                  Text('COPY',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor)),
                ],
              );
            } else if (action == 'action_cut') {
              labelWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scissors, size: 13, color: foregroundColor),
                  const SizedBox(width: 4),
                  Text('CUT',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor)),
                ],
              );
            } else {
              labelWidget = Text(
                key.$1,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  height: 36,
                  child: TextButton(
                    focusNode:
                        FocusNode(canRequestFocus: false, skipTraversal: true),
                    style: TextButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: borderColor,
                          width: isKeyActive ? 1.5 : 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(40, 36),
                    ),
                    onPressed: () {
                      onEnsureFocus();
                      if (isCtrl) {
                        onCtrlToggle();
                        return;
                      }
                      if (isAlt) {
                        onAltToggle();
                        return;
                      }
                      if (action == 'action_paste') {
                        onPaste();
                        return;
                      }
                      if (action == 'action_copy') {
                        onCopy();
                        return;
                      }
                      if (action == 'action_cut') {
                        onCut();
                        return;
                      }
                      if (action is TerminalKey) {
                        final handled = terminal.keyInput(action,
                            ctrl: isCtrlActive, alt: isAltActive);
                        if (!handled) {
                          if (action == TerminalKey.escape) {
                            onKeyPress('\x1b');
                          } else if (action == TerminalKey.tab) {
                            onKeyPress('\t');
                          } else if (action == TerminalKey.arrowUp) {
                            onKeyPress('\x1b[A');
                          } else if (action == TerminalKey.arrowDown) {
                            onKeyPress('\x1b[B');
                          } else if (action == TerminalKey.arrowLeft) {
                            onKeyPress('\x1b[D');
                          } else if (action == TerminalKey.arrowRight) {
                            onKeyPress('\x1b[C');
                          } else if (action == TerminalKey.home) {
                            onKeyPress('\x1b[H');
                          } else if (action == TerminalKey.end) {
                            onKeyPress('\x1b[F');
                          } else if (action == TerminalKey.pageUp) {
                            onKeyPress('\x1b[5~');
                          } else if (action == TerminalKey.pageDown) {
                            onKeyPress('\x1b[6~');
                          }
                        }
                        return;
                      }
                      if (action is String) {
                        onKeyPress(action);
                      }
                    },
                    child: labelWidget,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
