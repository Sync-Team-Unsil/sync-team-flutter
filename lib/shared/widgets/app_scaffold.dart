import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/notifications/notifications_provider.dart';

import '../../core/side_popup_provider.dart';
import 'side_popups/notification_sidebar.dart';
import 'side_popups/team_detail_sidebar.dart';
import 'side_popups/create_team_sidebar.dart';
import 'side_popups/manage_applicants_sidebar.dart';
import 'side_popups/edit_profile_sidebar.dart';
import 'notification_popup.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _routes = ['/home', '/profile'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexOf(location);
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTap(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final unreadCount = ref.watch(unreadCountProvider);
    final popupState = ref.watch(sidePopupProvider);

    // Listen for popup requests (Now only for side drawers like Team Detail/Manage Applicants)
    ref.listen(sidePopupProvider, (previous, next) {
      if (next.type != SidePopupType.none && next.type != SidePopupType.notifications) {
        _scaffoldKey.currentState?.openEndDrawer();
      } else if (next.type == SidePopupType.notifications) {
        _showNotificationPopup(context);
      } else {
        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
      }
    });

    if (isWide) {
      return _buildDesktopLayout(unreadCount, popupState);
    }
    return _buildMobileLayout(unreadCount, popupState);
  }

  // ─── DESKTOP LAYOUT ───
  Widget _buildDesktopLayout(int unreadCount, SidePopupState popupState) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _buildSidePopup(popupState),
      onEndDrawerChanged: (isOpen) {
        if (!isOpen) ref.read(sidePopupProvider.notifier).hide();
      },
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 32),
                // Nav items
                _SideNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                const SizedBox(height: 8),
                _SideNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                  onPressed: () => _handleLogout(context, ref),
                  tooltip: 'Logout',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Navbar (Top Bar)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentIndex == 0 ? 'Dashboard' : 'Profile',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      // Notif Icon
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                            onPressed: () => _showNotificationPopup(context),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Profile Mini
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.inputFill,
                        child: Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE LAYOUT ───
  Widget _buildMobileLayout(int unreadCount, SidePopupState popupState) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _buildSidePopup(popupState),
      onEndDrawerChanged: (isOpen) {
        if (!isOpen) ref.read(sidePopupProvider.notifier).hide();
      },
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Dashboard' : 'Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationPopup(context),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => const Center(
        child: NotificationPopup(),
      ),
    );
  }

  Widget _buildSidePopup(SidePopupState state) {
    return Drawer(
      width: 450,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: _getPopupContent(state),
    );
  }

  Widget _getPopupContent(SidePopupState state) {
    switch (state.type) {
      case SidePopupType.notifications:
        return const NotificationSidebar();
      case SidePopupType.createTeam:
        return const CreateTeamSidebar();
      case SidePopupType.teamDetail:
        return TeamDetailSidebar(teamId: state.data as String);
      case SidePopupType.manageApplicants:
        return ManageApplicantsSidebar(teamId: state.data as String);
      case SidePopupType.editProfile:
        return const EditProfileSidebar();
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(profileProvider.notifier).signOut();
    if (context.mounted) context.go('/auth');
  }
}

// ─── BOTTOM NAV ITEM (Mobile) ───
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIDE NAV ITEM (Desktop) ───
class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
