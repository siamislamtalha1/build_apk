import 'package:Bloomee/services/shortcut_indicator_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:just_audio/just_audio.dart';

/// Global overlay widget that shows animated shortcut indicators.
/// Place this high in the widget tree to show indicators anywhere in the app.
class ShortcutIndicatorOverlay extends StatelessWidget {
  final Widget child;

  const ShortcutIndicatorOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          BlocBuilder<ShortcutIndicatorCubit, ShortcutIndicatorState>(
            builder: (context, state) {
              return _ShortcutIndicator(state: state);
            },
          ),
        ],
      ),
    );
  }
}

class _ShortcutIndicator extends StatefulWidget {
  final ShortcutIndicatorState state;

  const _ShortcutIndicator({required this.state});

  @override
  State<_ShortcutIndicator> createState() => _ShortcutIndicatorState();
}

class _ShortcutIndicatorState extends State<_ShortcutIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutQuart,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeOutQuart,
      ),
    );

    if (widget.state.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _ShortcutIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isVisible != oldWidget.state.isVisible) {
      if (widget.state.isVisible) {
        _animationController.forward(from: 0);
      } else {
        _animationController.reverse();
      }
    } else if (widget.state.isVisible) {
      // State changed but still visible - show update animation
      _animationController.forward(from: 0.7);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.isVisible &&
        _animationController.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: _buildIndicatorContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIndicatorContent(BuildContext context) {
    final type = widget.state.type;
    if (type == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: (isDark ? Default_Theme.themeColor : scheme.surface)
              .withValues(alpha: isDark ? 0.75 : 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : scheme.shadow)
                  .withValues(alpha: isDark ? 0.15 : 0.10),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: (isDark ? Colors.black : scheme.shadow)
                  .withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context, type),
            const SizedBox(height: 12),
            _buildLabel(context, type),
            if (_shouldShowProgressBar(type)) ...[
              const SizedBox(height: 12),
              _buildProgressBar(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, ShortcutIndicatorType type) {
    final IconData icon;
    final Color color;

    final scheme = Theme.of(context).colorScheme;

    switch (type) {
      case ShortcutIndicatorType.volume:
        final level = widget.state.volumeLevel ?? 0;
        if (level == 0) {
          icon = MingCute.volume_off_fill;
          color = scheme.onSurface.withValues(alpha: 0.6);
        } else if (level < 0.3) {
          icon = MingCute.volume_fill;
          color = scheme.onSurface;
        } else if (level < 0.7) {
          icon = MingCute.volume_fill;
          color = scheme.onSurface;
        } else {
          icon = MingCute.volume_fill;
          color = scheme.onSurface;
        }
        break;

      case ShortcutIndicatorType.mute:
        final isMuted = widget.state.isMuted ?? false;
        icon = isMuted ? MingCute.volume_off_fill : MingCute.volume_fill;
        color = isMuted
            ? scheme.onSurface.withValues(alpha: 0.6)
            : scheme.primary;
        break;

      case ShortcutIndicatorType.shuffle:
        icon = MingCute.shuffle_2_line;
        color = (widget.state.isShuffleOn ?? false)
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.6);
        break;

      case ShortcutIndicatorType.loop:
        final mode = widget.state.loopMode ?? LoopMode.off;
        switch (mode) {
          case LoopMode.off:
            icon = MingCute.repeat_line;
            color = scheme.onSurface.withValues(alpha: 0.6);
            break;
          case LoopMode.one:
            icon = MingCute.repeat_one_line;
            color = scheme.primary;
            break;
          case LoopMode.all:
            icon = MingCute.repeat_line;
            color = scheme.primary;
            break;
        }
        break;

      case ShortcutIndicatorType.like:
        final isLiked = widget.state.isLiked ?? false;
        icon = isLiked ? AntDesign.heart_fill : AntDesign.heart_outline;
        color = isLiked ? scheme.primary : scheme.onSurface;
        break;
    }

    return Icon(
      icon,
      size: 48,
      color: color,
    );
  }

  Widget _buildLabel(BuildContext context, ShortcutIndicatorType type) {
    final String label;
    final Color? labelColor;

    final scheme = Theme.of(context).colorScheme;

    switch (type) {
      case ShortcutIndicatorType.volume:
        final level = widget.state.volumeLevel ?? 0;
        label = '${(level * 100).round()}%';
        labelColor = null;
        break;

      case ShortcutIndicatorType.mute:
        final isMuted = widget.state.isMuted ?? false;
        label = isMuted ? 'Muted' : 'Unmuted';
        labelColor = null;
        break;

      case ShortcutIndicatorType.shuffle:
        final isOn = widget.state.isShuffleOn ?? false;
        label = isOn ? 'Shuffle On' : 'Shuffle Off';
        labelColor = isOn ? scheme.primary : null;
        break;

      case ShortcutIndicatorType.loop:
        final mode = widget.state.loopMode ?? LoopMode.off;
        switch (mode) {
          case LoopMode.off:
            label = 'Repeat Off';
            labelColor = null;
            break;
          case LoopMode.one:
            label = 'Repeat One';
            labelColor = scheme.primary;
            break;
          case LoopMode.all:
            label = 'Repeat All';
            labelColor = scheme.primary;
            break;
        }
        break;

      case ShortcutIndicatorType.like:
        final isLiked = widget.state.isLiked ?? false;
        label = isLiked ? 'Liked' : 'Unliked';
        labelColor = isLiked ? scheme.primary : null;
        break;
    }

    return Text(
      label,
      style: Default_Theme.secondoryTextStyleMedium.copyWith(
        fontSize: 16,
        color: labelColor ?? scheme.onSurface,
      ),
    );
  }

  bool _shouldShowProgressBar(ShortcutIndicatorType type) {
    return type == ShortcutIndicatorType.volume ||
        type == ShortcutIndicatorType.mute;
  }

  Widget _buildProgressBar(BuildContext context) {
    final level = widget.state.volumeLevel ?? 0;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: level, end: level),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 0
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
            );
          },
        ),
      ),
    );
  }
}
