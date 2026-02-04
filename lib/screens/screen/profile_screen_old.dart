import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/services/sync/sync_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';

/// User profile screen with account management and sync status
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return _buildNotLoggedIn(context);
          }

          final user = state.user;
          final isGuest = user.isAnonymous;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Default_Theme.themeColor,
                actions: [
                  IconButton(
                    icon: Icon(MingCute.settings_3_line,
                        color: scheme.onSurface),
                    onPressed: () => context.push('/Settings'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Default_Theme.accentColor2.withValues(alpha: 0.3),
                          Default_Theme.themeColor,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Profile Picture
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Default_Theme.accentColor2,
                          backgroundImage: user.photoURL != null
                              ? safeImageProvider(user.photoURL)
                              : null,
                          child: user.photoURL == null
                              ? Icon(
                                  isGuest
                                      ? MingCute.user_3_line
                                      : MingCute.user_4_fill,
                                  size: 50,
                                  color: scheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Text(
                          user.displayName ?? (isGuest ? 'Guest User' : 'User'),
                          style: Default_Theme.primaryTextStyle.merge(
                            TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Default_Theme.primaryColor1,
                            ),
                          ),
                        ),
                        if (!isGuest && user.email != null)
                          Text(
                            user.email!,
                            style: Default_Theme.secondoryTextStyle.merge(
                              TextStyle(
                                fontSize: 14,
                                color: Default_Theme.primaryColor2,
                              ),
                            ),
                          ),
                        if (isGuest)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Default_Theme.accentColor2
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Guest Mode',
                              style: Default_Theme.secondoryTextStyle.merge(
                                TextStyle(
                                  fontSize: 12,
                                  color: Default_Theme.accentColor2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guest Mode Upgrade Banner
                      if (isGuest) _buildGuestUpgradeBanner(context),

                      const SizedBox(height: 24),

                      // Account Section
                      _buildSectionTitle('Account'),
                      const SizedBox(height: 12),
                      _buildAccountCard(context, user, isGuest),

                      const SizedBox(height: 24),

                      // Sync Status Section
                      _buildSectionTitle('Sync Status'),
                      const SizedBox(height: 12),
                      _buildSyncStatusCard(context),

                      const SizedBox(height: 24),

                      // Statistics Section
                      _buildSectionTitle('Your Stats'),
                      const SizedBox(height: 12),
                      _buildStatsCard(context),

                      const SizedBox(height: 24),

                      // Sign Out Button
                      _buildSignOutButton(context),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
            Text(
              'Not Logged In',
              style: Default_Theme.primaryTextStyle.merge(
                TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Default_Theme.primaryColor1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to sync your music across devices',
              textAlign: TextAlign.center,
              style: Default_Theme.secondoryTextStyle.merge(
                TextStyle(
                  fontSize: 16,
                  color: Default_Theme.primaryColor2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Default_Theme.accentColor2,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestUpgradeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Default_Theme.accentColor2.withValues(alpha: 0.2),
            Default_Theme.accentColor2.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Default_Theme.accentColor2.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            MingCute.information_line,
            color: Default_Theme.accentColor2,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade Your Account',
                  style: Default_Theme.primaryTextStyle.merge(
                    TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Default_Theme.primaryColor1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an account to save your data permanently',
                  style: Default_Theme.secondoryTextStyle.merge(
                    TextStyle(
                      fontSize: 14,
                      color: Default_Theme.primaryColor2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => context.push('/Signup'),
            child: Text(
              'Upgrade',
              style: Default_Theme.secondoryTextStyle.merge(
                TextStyle(
                  color: Default_Theme.accentColor2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Default_Theme.primaryTextStyle.merge(
        TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Default_Theme.primaryColor1,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, user, bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Default_Theme.primaryColor1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Default_Theme.primaryColor1.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: MingCute.user_3_line,
            label: 'Account Type',
            value: isGuest ? 'Guest' : 'Registered',
          ),
          if (!isGuest && user.email != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              icon: MingCute.mail_line,
              label: 'Email',
              value: user.email!,
            ),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            icon: MingCute.calendar_line,
            label: 'Member Since',
            value: _formatDate(user.metadata.creationTime),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService().syncStatus,
      initialData: SyncStatus.idle,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;

        String statusText;
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case SyncStatus.syncing:
            statusText = 'Syncing...';
            statusColor = Colors.blue;
            statusIcon = MingCute.loading_fill;
            break;
          case SyncStatus.error:
            statusText = 'Error';
            statusColor = Colors.red;
            statusIcon = MingCute.close_circle_fill;
            break;
          case SyncStatus.synced:
          case SyncStatus.idle:
            statusText = 'Synced';
            statusColor = Colors.green;
            statusIcon = MingCute.check_circle_fill;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Default_Theme.primaryColor1.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Default_Theme.primaryColor1.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildSyncRow(
                icon: MingCute.heart_fill,
                label: 'Liked Songs',
                status: statusText,
                statusIcon: statusIcon,
                color: statusColor,
              ),
              const Divider(height: 24),
              _buildSyncRow(
                icon: MingCute.music_2_line,
                label: 'Playlists',
                status: statusText,
                statusIcon: statusIcon,
                color: statusColor,
              ),
              const Divider(height: 24),
              _buildSyncRow(
                icon: MingCute.chart_line_line,
                label: 'Statistics',
                status: statusText,
                statusIcon: statusIcon,
                color: statusColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Default_Theme.primaryColor1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Default_Theme.primaryColor1.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: MingCute.music_2_fill,
            label: 'Songs',
            value: '0',
          ),
          _buildStatItem(
            icon: MingCute.album_line,
            label: 'Playlists',
            value: '0',
          ),
          _buildStatItem(
            icon: MingCute.time_line,
            label: 'Hours',
            value: '0',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Default_Theme.primaryColor2,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Default_Theme.secondoryTextStyle.merge(
                  TextStyle(
                    fontSize: 12,
                    color: Default_Theme.primaryColor2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Default_Theme.primaryTextStyle.merge(
                  TextStyle(
                    fontSize: 14,
                    color: Default_Theme.primaryColor1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        Icon(
          icon,
          size: 20,
          color: Default_Theme.primaryColor2,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Default_Theme.primaryTextStyle.merge(
              TextStyle(
                fontSize: 14,
                color: Default_Theme.primaryColor1,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: Default_Theme.secondoryTextStyle.merge(
                  TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Default_Theme.accentColor2,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Default_Theme.primaryTextStyle.merge(
            TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Default_Theme.primaryColor1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Default_Theme.secondoryTextStyle.merge(
            TextStyle(
              fontSize: 12,
              color: Default_Theme.primaryColor2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Default_Theme.themeColor,
              title: Text(
                'Sign Out',
                style: Default_Theme.primaryTextStyle.merge(
                  TextStyle(
                    color: Default_Theme.primaryColor1,
                  ),
                ),
              ),
              content: Text(
                'Are you sure you want to sign out?',
                style: Default_Theme.secondoryTextStyle.merge(
                  TextStyle(
                    color: Default_Theme.primaryColor2,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: Default_Theme.secondoryTextStyle.merge(
                      TextStyle(
                        color: Default_Theme.primaryColor2,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthCubit>().signOut();
                    Navigator.pop(context);
                    context.go('/Explore');
                  },
                  child: Text(
                    'Sign Out',
                    style: Default_Theme.secondoryTextStyle.merge(
                      const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(MingCute.exit_line),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
