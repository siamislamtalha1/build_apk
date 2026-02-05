import 'dart:ui';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/services/sync/sync_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:Bloomee/screens/widgets/glass_widgets.dart';

/// Game-style user profile screen with glassmorphic design
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showUsernameDialog(
    BuildContext context, {
    required String title,
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return GlassDialog(
          title: Text(
            title,
            style: TextStyle(color: scheme.onSurface),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '@username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final v = (next ?? '').trim();
    if (v.isEmpty) return;
    try {
      await context.read<AuthCubit>().updateUsername(v);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username updated'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final footerSafeSpace = MediaQuery.of(context).padding.bottom + 160;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return _buildNotLoggedIn(context);
          }

          final user = state.user;
          final isGuest = user.isAnonymous;

          return SafeArea(
            bottom: false,
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
                SliverToBoxAdapter(
                  child: SizedBox(height: footerSafeSpace),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isGuest) {
    final firestore = FirestoreService();
    final scheme = Theme.of(context).colorScheme;
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
                      scheme.primary.withValues(alpha: 0.2),
                      scheme.surface.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.1),
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
                                color: scheme.primary.withValues(alpha: 0.4),
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
                              color: scheme.primary,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.3),
                            backgroundImage: user.photoURL != null
                                ? safeImageProvider(user.photoURL)
                                : null,
                            child: user.photoURL == null
                                ? Icon(
                                    isGuest
                                        ? MingCute.user_3_line
                                        : MingCute.user_4_fill,
                                    size: 48,
                                    color: scheme.primary,
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
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              MingCute.user_4_fill,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // User name
                    Text(
                      user.displayName ?? (isGuest ? 'Guest User' : 'User'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isGuest)
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: firestore.watchUserProfile(user.uid),
                        builder: (context, snap) {
                          final username = snap.data?['username'] as String?;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (username == null || username.trim().isEmpty)
                                    ? 'Set username'
                                    : username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: scheme.primary.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () async {
                                  await _showUsernameDialog(
                                    context,
                                    title: (username == null ||
                                            username.trim().isEmpty)
                                        ? 'Set username'
                                        : 'Change username',
                                    initial: username,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    MingCute.edit_line,
                                    size: 16,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    // Email or guest badge
                    if (!isGuest && user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    if (isGuest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'GUEST MODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: StreamBuilder<SyncDetails>(
            stream: SyncService().syncDetails,
            initialData: const SyncDetails(
              status: SyncStatus.idle,
              initialSyncInProgress: false,
              syncingLikedSongs: false,
              syncingPlaylists: false,
              syncingHistory: false,
              syncingSearchHistory: false,
              syncingPreferences: false,
              syncingStatistics: false,
              likedSongsCount: 0,
              playlistsCount: 0,
              playlistItemsCount: 0,
              historyCount: 0,
              searchHistoryCount: 0,
              settingsBoolCount: 0,
              settingsStrCount: 0,
              statisticsCount: 0,
              lastSuccessfulSyncAt: null,
            ),
            builder: (context, snapshot) {
              final details = snapshot.data;
              final status = details?.status ?? SyncStatus.idle;

              String statusText;
              IconData statusIcon;
              Color statusColor;

              switch (status) {
                case SyncStatus.syncing:
                  statusText = (details?.initialSyncInProgress ?? true)
                      ? 'Syncing...'
                      : 'Synced';
                  statusIcon = MingCute.loading_3_fill;
                  statusColor = scheme.primary;
                  break;
                case SyncStatus.synced:
                  statusText = 'Synced';
                  statusIcon = MingCute.check_circle_fill;
                  statusColor = scheme.primary;
                  break;
                case SyncStatus.error:
                  statusText = 'Sync Error';
                  statusIcon = MingCute.close_circle_fill;
                  statusColor = Colors.red;
                  break;
                default:
                  statusText = 'Ready';
                  statusIcon = MingCute.cloud_fill;
                  statusColor = scheme.onSurface.withValues(alpha: 0.7);
              }

              final likedCount = details?.likedSongsCount ?? 0;
              final plCount = details?.playlistsCount ?? 0;
              final plItemsCount = details?.playlistItemsCount ?? 0;
              final historyCount = details?.historyCount ?? 0;
              final searchCount = details?.searchHistoryCount ?? 0;
              final settingsCount =
                  (details?.settingsBoolCount ?? 0) + (details?.settingsStrCount ?? 0);
              final statsCount = details?.statisticsCount ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(MingCute.cloud_fill, color: scheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Cloud Sync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
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
                    trailingText: '$likedCount',
                    isSyncing: details?.syncingLikedSongs ?? false,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.music_2_fill,
                    label: 'Playlists',
                    trailingText: '$plCount • $plItemsCount',
                    isSyncing: details?.syncingPlaylists ?? false,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.time_fill,
                    label: 'Listened History',
                    trailingText: '$historyCount',
                    isSyncing: details?.syncingHistory ?? false,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.search_fill,
                    label: 'Search History',
                    trailingText: '$searchCount',
                    isSyncing: details?.syncingSearchHistory ?? false,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.settings_3_fill,
                    label: 'Settings',
                    trailingText: '$settingsCount',
                    isSyncing: details?.syncingPreferences ?? false,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _buildSyncRow(
                    icon: MingCute.chart_line_fill,
                    label: 'Statistics',
                    trailingText: '$statsCount',
                    isSyncing: details?.syncingStatistics ?? false,
                    scheme: scheme,
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
    required String trailingText,
    required bool isSyncing,
    required ColorScheme scheme,
  }) {
    return Row(
      children: [
        Icon(icon, color: scheme.onSurface.withValues(alpha: 0.75), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Text(
          trailingText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          isSyncing ? MingCute.loading_3_fill : MingCute.check_circle_fill,
          color: isSyncing
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.6),
          size: 16,
        ),
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
          onTap: () => context.push('/About'),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          context: context,
          icon: MingCute.chart_bar_fill,
          title: 'Statistics',
          subtitle: 'Your listening stats',
          onTap: () => context.push('/Statistics'),
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
          const SizedBox(height: 12),
          _buildMenuItem(
            context: context,
            icon: MingCute.delete_2_fill,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () => _showDeleteAccountDialog(context),
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return GlassDialog(
          title: Text(
            'Delete Account',
            style: TextStyle(color: scheme.onSurface),
          ),
          content: Text(
            'This will permanently delete your account. Your username will become available again.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await context.read<AuthCubit>().deleteAccount();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.3)
                  : scheme.onSurface.withValues(alpha: 0.08),
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
                                : scheme.primary)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isDestructive
                            ? Colors.red
                            : scheme.primary,
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
                                  : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      MingCute.right_line,
                      color: scheme.onSurface.withValues(alpha: 0.5),
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
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/Login?from=profile'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MingCute.user_add_fill,
                        color: scheme.onPrimary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Sign In to Sync',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimary,
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MingCute.user_3_line,
              size: 100,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Not Logged In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to sync your music across devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withValues(alpha: 0.7),
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
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return GlassDialog(
          title: Text(
            'Sign Out',
            style: TextStyle(color: scheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
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
        );
      },
    );
  }
}
