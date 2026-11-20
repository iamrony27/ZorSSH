import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/features/connect/presentation/screens/add_server_screen.dart';
import 'package:aetherssh/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:aetherssh/features/files/presentation/screens/files_screen.dart';
import 'package:aetherssh/features/home/screens/home_screen.dart';
import 'package:aetherssh/features/terminal/presentation/screens/terminal_screen.dart';
import 'package:aetherssh/features/server_details/presentation/screens/server_details_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/settings_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/manage_servers_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/change_pin_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/about_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/licenses_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/legal_document_screen.dart';
import 'package:aetherssh/features/settings/presentation/screens/ai_settings_screen.dart';
import 'package:aetherssh/features/services/presentation/screens/service_manager_screen.dart';
import 'package:aetherssh/core/models/server.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final mediaQuery = MediaQuery.of(context);
        final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
        final systemBottom = mediaQuery.padding.bottom;
        final bottomMargin = systemBottom == 0 ? 16.0 : systemBottom;
        final navBarHeight = 64.0 + bottomMargin;
        final navBarClearance = isKeyboardOpen
            ? systemBottom
            : (navBarHeight + 16.0);

        return Scaffold(
          extendBody: true,
          backgroundColor:
              Colors.transparent, // Let underlying screens show background
          body: MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(bottom: navBarClearance),
              viewPadding: mediaQuery.viewPadding.copyWith(
                bottom: navBarClearance,
              ),
            ),
            child: child,
          ),
          bottomNavigationBar: isKeyboardOpen
              ? const SizedBox.shrink()
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131722)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildNavItem(
                                      context,
                                      0,
                                      LucideIcons.layoutDashboard,
                                      'Dashboard',
                                      _calculateSelectedIndex(context),
                                    ),
                                    _buildNavItem(
                                      context,
                                      1,
                                      LucideIcons.terminal,
                                      'Terminal',
                                      _calculateSelectedIndex(context),
                                    ),
                                    _buildNavItem(
                                      context,
                                      2,
                                      LucideIcons.folderClosed,
                                      'Files',
                                      _calculateSelectedIndex(context),
                                    ),
                                    _buildNavItem(
                                      context,
                                      3,
                                      LucideIcons.settings,
                                      'Settings',
                                      _calculateSelectedIndex(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _buildSectionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/dashboard/:serverId',
          pageBuilder: (context, state) {
            final serverId = state.pathParameters['serverId']!;
            return _buildSectionPage(
              key: state.pageKey,
              child: DashboardScreen(serverId: serverId),
            );
          },
        ),
        GoRoute(
          path: '/terminal',
          pageBuilder: (context, state) => _buildSectionPage(
            key: state.pageKey,
            child: const TerminalScreen(),
          ),
        ),
        GoRoute(
          path: '/files',
          pageBuilder: (context, state) => _buildSectionPage(
            key: state.pageKey,
            child: const FilesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildSectionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
    // ── Modal sub-screens outside ShellRoute so bottom navigation bar does NOT overlay them [UI-005] ──
    GoRoute(
      path: '/add-server',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final existingServer = state.extra is Server
            ? state.extra as Server
            : null;
        return _buildSubScreenPage(
          key: state.pageKey,
          child: AddServerScreen(existingServer: existingServer),
        );
      },
    ),
    GoRoute(
      path: '/server-details',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) {
        if (state.extra is! Server) {
          return '/';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final server = state.extra as Server;
        return _buildSubScreenPage(
          key: state.pageKey,
          child: ServerDetailsScreen(server: server),
        );
      },
    ),
    GoRoute(
      path: '/change-pin',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildSubScreenPage(
        key: state.pageKey,
        child: const ChangePinScreen(),
      ),
    ),
    GoRoute(
      path: '/manage-servers',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildSubScreenPage(
        key: state.pageKey,
        child: const ManageServersScreen(),
      ),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildSubScreenPage(
        key: state.pageKey,
        child: const AboutScreen(),
      ),
    ),
    GoRoute(
      path: '/ai-settings',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildSubScreenPage(
        key: state.pageKey,
        child: const AiSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/services',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) {
        if (state.extra is! Server) {
          return '/';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final server = state.extra as Server;
        return _buildSubScreenPage(
          key: state.pageKey,
          child: ServiceManagerScreen(server: server),
        );
      },
    ),
    GoRoute(
      path: '/licenses',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildSubScreenPage(
        key: state.pageKey,
        child: const LicensesScreen(),
      ),
    ),
    GoRoute(
      path: '/legal',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) {
        if (state.extra is! Map<String, dynamic>) {
          return '/';
        }
        final args = state.extra as Map<String, dynamic>;
        if (args['title'] is! String || args['assetPath'] is! String) {
          return '/';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return _buildSubScreenPage(
          key: state.pageKey,
          child: LegalDocumentScreen(
            title: args['title'] as String,
            assetPath: args['assetPath'] as String,
          ),
        );
      },
    ),
  ],
);

Page<dynamic> _buildSectionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.035),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _buildSubScreenPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}

int _calculateSelectedIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.toString();
  if (location.startsWith('/terminal')) {
    return 1;
  }
  if (location.startsWith('/files')) {
    return 2;
  }
  if (location.startsWith('/settings')) {
    return 3;
  }
  return 0;
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      GoRouter.of(context).go('/');
      break;
    case 1:
      GoRouter.of(context).go('/terminal');
      break;
    case 2:
      GoRouter.of(context).go('/files');
      break;
    case 3:
      GoRouter.of(context).go('/settings');
      break;
  }
}

Widget _buildNavItem(
  BuildContext context,
  int index,
  IconData icon,
  String label,
  int selectedIndex,
) {
  final isSelected = selectedIndex == index;
  final activeColor = const Color(0xFF00E676);
  final inactiveColor = const Color(0xFF8E95A5);

  return Expanded(
    child: InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 18 : 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            style: GoogleFonts.inter(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: isSelected ? 11.0 : 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
