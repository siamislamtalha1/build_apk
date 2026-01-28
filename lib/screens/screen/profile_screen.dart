import 'dart:ui';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/services/sync/sync_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';

/// Game-style user profile screen with glassmorphic design
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return _buildNotLoggedIn(context);
          }

          final user = state.user;
          final isGuest = user.isAnonymous;

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header with profile card
                SliverToBoxAdapter(
                  child: _buildProfileHeader(context, user, isGuest),
                ),

                // Menu items
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (!isGuest) _buildSyncStatusCard(context),
                        const SizedBox(height: 16),
                        _buildMenuSection(context, isGuest),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Glassmorphic profile card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Default_Theme.accentColor2.withValues(alpha: 0.2),
                      Default_Theme.themeColor.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Profile picture with glow effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Default_Theme.accentColor2
                                    .withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        // Profile picture
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Default_Theme.accentColor2,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Default_Theme.accentColor2
                                .withValues(alpha: 0.3),
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Icon(
                                    isGuest
                                        ? MingCute.user_3_line
                                        : MingCute.user_4_fill,
                                    size: 48,
                                    color: Default_Theme.accentColor2,
                                  )
                                : null,
                          ),
                        ),
                        // Account icon badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Default_Theme.accentColor2,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Default_Theme.themeColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              MingCute.user_4_fill,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // User name
                    Text(
                      user.displayName ?? (isGuest ? 'Guest User' : 'User'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Default_Theme.primaryColor1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email or guest badge
                    if (!isGuest && user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Default_Theme.primaryColor2
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    if (isGuest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              Default_Theme.accentColor2.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Default_Theme.accentColor2
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'GUEST MODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Default_Theme.accentColor2,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Default_Theme.themeColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: StreamBuilder<SyncStatus>(
            stream: SyncService().syncStatus,
            initialData: SyncStatus.idle,
            builder: (context, snapshot) {
              final status = snapshot.data ?? SyncStatus.idle;

              String statusText;
              IconData statusIcon;
              Color statusColor;

              switch (status) {
                case SyncStatus.syncing:
                  statusText = 'Syncing...';
                  statusIcon = MingCute.loading_3_fill;
                  statusColor = Default_Theme.accentColor2;
                  break;
                case SyncStatus.synced:
                  statusText = 'Synced';
                  statusIcon = MingCute.check_circle_fill;
                  statusColor = Colors.green;
                  break;
                case SyncStatus.error:
                  statusText = 'Sync Error';
                  statusIcon = MingCute.close_circle_fill;
                  statusColor = Colors.red;
                  break;
                default:
                  statusText = 'Ready';
                  statusIcon = MingCute.cloud_fill;
                  statusColor = Default_Theme.primaryColor2;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(MingCute.cloud_fill,
                          color: Default_Theme.accentColor2, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Cloud Sync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Default_Theme.primaryColor1,
                        ),
                      ),
                      const Spacer(),
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSyncRow(
                    icon: MingCute.heart_fill,
                    label: 'Liked Songs',
                    status: statusText,
                    statusIcon: statusIcon,
                    color: statusColor,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.music_2_fill,
                    label: 'Playlists',
                    status: statusText,
                    statusIcon: statusIcon,
                    color: statusColor,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.chart_line_fill,
                    label: 'Statistics',
                    status: statusText,
                    statusIcon: statusIcon,
                    color: statusColor,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSyncRow({
    required IconData icon,
    required String label,
    required String status,
    required IconData statusIcon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: Default_Theme.primaryColor2, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Default_Theme.primaryColor2,
          ),
        ),
        const Spacer(),
        Icon(statusIcon, color: color, size: 16),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isGuest) {
    return Column(
      children: [
        _buildMenuItem(
          context: context,
          icon: MingCute.settings_3_fill,
          title: 'Settings',
          subtitle: 'App preferences and configuration',
          onTap: () => context.push('/Settings'),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: MingCute.information_fill,
          title: 'About',
          subtitle: 'App information and developer',
          onTap: () => context.push('/Settings/About'),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: MingCute.chart_bar_fill,
          title: 'Statistics',
          subtitle: 'Your listening stats',
          onTap: () {
            // Navigate to stats
          },
        ),
        if (!isGuest) ...[
          const SizedBox(height: 12),
          _buildMenuItem(
            context: context,
            icon: MingCute.exit_fill,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            onTap: () => _showSignOutDialog(context),
            isDestructive: true,
          ),
        ],
        if (isGuest) ...[
          const SizedBox(height: 20),
          _buildSignInButton(context),
        ],
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Default_Theme.themeColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDestructive
                                ? Colors.red
                                : Default_Theme.accentColor2)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isDestructive
                            ? Colors.red
                            : Default_Theme.accentColor2,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDestructive
                                  ? Colors.red
                                  : Default_Theme.primaryColor1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Default_Theme.primaryColor2
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      MingCute.right_line,
                      color: Default_Theme.primaryColor2.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Default_Theme.accentColor2,
                Default_Theme.accentColor2.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Default_Theme.accentColor2.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/Login'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(MingCute.user_add_fill,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign In to Sync',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MingCute.user_3_line,
              size: 100,
              color: Default_Theme.primaryColor2.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not Logged In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Default_Theme.primaryColor1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to sync your music across devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Default_Theme.primaryColor2.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            _buildSignInButton(context),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Default_Theme.themeColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Default_Theme.primaryColor1),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Default_Theme.primaryColor2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthCubit>().signOut();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
