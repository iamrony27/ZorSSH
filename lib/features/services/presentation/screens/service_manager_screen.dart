import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:zorssh/core/models/server.dart';
import 'package:zorssh/core/providers.dart';
import 'package:zorssh/core/services/os_detector.dart';
import 'package:zorssh/core/services/service_management_service.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/core/widgets/os_icon.dart';
import 'package:zorssh/core/widgets/system_card.dart';

class ServiceManagerScreen extends ConsumerStatefulWidget {
  final Server server;

  const ServiceManagerScreen({super.key, required this.server});

  @override
  ConsumerState<ServiceManagerScreen> createState() =>
      _ServiceManagerScreenState();
}

class _ServiceManagerScreenState extends ConsumerState<ServiceManagerScreen> {
  SSHClient? _client;
  OsInfo _osInfo = OsInfo.unknown;
  List<ManagedServiceItem> _services = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  ServiceStatus? _statusFilter;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _osInfo = OsInfo.fromDistroString(widget.server.osDistro);
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _client?.close();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_client == null) {
        final ssh = ref.read(sshServiceProvider);
        _client = await ssh.connect(
          widget.server.hostname,
          widget.server.port,
          widget.server.username,
          widget.server.id,
        );

        if (_osInfo.type == OsType.unknown) {
          _osInfo = await OsDetector.detect(_client!);
        }
      }

      final services = await ServiceManagementService.listServices(
        client: _client!,
        osInfo: _osInfo,
      );

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load services: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(
    ManagedServiceItem service,
    ServiceAction action, {
    bool useSudo = false,
  }) async {
    if (_client == null) return;

    final actionWord = action == ServiceAction.start
        ? 'Starting'
        : action == ServiceAction.stop
            ? 'Stopping'
            : 'Restarting';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionWord ${service.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await ServiceManagementService.executeAction(
      client: _client!,
      osInfo: _osInfo,
      serviceName: service.name,
      action: action,
      useSudo: useSudo,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E293B),
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppTheme.terminalMint, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      // Reload services to reflect updated status
      _loadServices();
    } else {
      if (result.isPermissionDenied && !_osInfo.isWindows && !useSudo) {
        // Offer to retry with sudo
        _showSudoRetryDialog(service, action);
      } else {
        _showErrorDialog(
          title: 'Action Failed',
          message: result.message,
        );
      }
    }
  }

  void _showSudoRetryDialog(ManagedServiceItem service, ServiceAction action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, color: Colors.amber, size: 22),
            const SizedBox(width: 10),
            Text(
              'Sudo Required',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Managing system service "${service.name}" requires root privileges. Would you like to retry using "sudo"?',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terminalMint,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(service, action, useSudo: true);
            },
            child: Text('Retry with sudo', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConfirmActionDialog(ManagedServiceItem service, ServiceAction action) {
    final isStop = action == ServiceAction.stop;
    final actionName = isStop ? 'Stop' : 'Restart';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isStop ? LucideIcons.alertTriangle : LucideIcons.refreshCw,
              color: isStop ? Colors.redAccent : Colors.amber,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              '$actionName Service?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$actionName "${service.displayName}" (${service.name})?\n\nThis may interrupt active network connections or background tasks.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isStop ? Colors.redAccent : Colors.amber,
              foregroundColor: isStop ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(service, action);
            },
            child: Text(actionName, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.inter(color: AppTheme.terminalMint)),
          ),
        ],
      ),
    );
  }

  List<ManagedServiceItem> get _filteredServices {
    return _services.where((s) {
      if (_statusFilter != null && s.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = s.name.toLowerCase().contains(q);
        final matchesDisplay = s.displayName.toLowerCase().contains(q);
        return matchesName || matchesDisplay;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices;
    final runningCount = _services.where((s) => s.isRunning).length;
    final stoppedCount = _services.where((s) => s.isStopped).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search service name or description...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Services',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Row(
                    children: [
                      OsIconWidget(osInfo: _osInfo, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.server.name} • ${_osInfo.isWindows ? "PowerShell" : "systemd"}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? LucideIcons.x : LucideIcons.search,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white70),
            onPressed: _isLoading ? null : _loadServices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'All (${_services.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(ServiceStatus.running, 'Running ($runningCount)', color: AppTheme.terminalMint),
                  const SizedBox(width: 8),
                  _buildFilterChip(ServiceStatus.stopped, 'Stopped ($stoppedCount)', color: Colors.white54),
                ],
              ),
            ),
          ),

          // Main body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.terminalMint),
                        SizedBox(height: 16),
                        Text(
                          'Querying remote services...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 40),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadServices,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.terminalMint,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No services matching "$_searchQuery"'
                                  : 'No services found.',
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadServices,
                            color: AppTheme.terminalMint,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final service = filtered[index];
                                return _buildServiceTile(service);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ServiceStatus? status, String label, {Color? color}) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      selectedColor: color ?? AppTheme.terminalMint,
      backgroundColor: const Color(0xFF1E2028),
      side: BorderSide(
        color: isSelected ? Colors.transparent : Colors.white12,
      ),
      onSelected: (val) {
        setState(() {
          _statusFilter = val ? status : null;
        });
      },
    );
  }

  Widget _buildServiceTile(ManagedServiceItem service) {
    final statusColor = service.isRunning
        ? AppTheme.terminalMint
        : service.isFailed
            ? Colors.redAccent
            : Colors.white38;

    return SystemCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (service.isRunning)
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Service Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              service.status.name.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Actions Popup Menu
          PopupMenuButton<ServiceAction>(
            icon: const Icon(LucideIcons.moreVertical, size: 18, color: Colors.white54),
            color: const Color(0xFF1E2028),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              if (!service.isRunning)
                PopupMenuItem(
                  value: ServiceAction.start,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.play, color: AppTheme.terminalMint, size: 16),
                      const SizedBox(width: 10),
                      Text('Start Service', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              if (service.isRunning) ...[
                PopupMenuItem(
                  value: ServiceAction.restart,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.refreshCw, color: Colors.amber, size: 16),
                      const SizedBox(width: 10),
                      Text('Restart Service', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ServiceAction.stop,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.square, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 10),
                      Text('Stop Service', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
            onSelected: (action) {
              if (action == ServiceAction.start) {
                _handleAction(service, action);
              } else {
                _showConfirmActionDialog(service, action);
              }
            },
          ),
        ],
      ),
    );
  }
}
