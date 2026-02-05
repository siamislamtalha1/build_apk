import 'dart:ui';

import 'package:flutter/material.dart';

double headerPillTopPadding(BuildContext context, {double? spacing}) {
  final mq = MediaQuery.of(context);
  final shortestSide = mq.size.shortestSide;
  final dynamicSpacing = (shortestSide * 0.02).clamp(6.0, 14.0);
  return mq.padding.top + (spacing ?? dynamicSpacing);
}

double headerPillTopSpacing(BuildContext context) {
  final mq = MediaQuery.of(context);
  final shortestSide = mq.size.shortestSide;
  return (shortestSide * 0.02).clamp(6.0, 14.0);
}

class GlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double sigmaX;
  final double sigmaY;
  final double borderOpacity;
  final double darkTintOpacity;
  final double lightTintOpacity;

  const GlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding,
    this.sigmaX = 25,
    this.sigmaY = 25,
    this.borderOpacity = 0.12,
    this.darkTintOpacity = 0.06,
    this.lightTintOpacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? darkTintOpacity : lightTintOpacity);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: borderRadius,
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: borderOpacity),
          width: 1.0,
        ),
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: content,
      ),
    );
  }
}

class HeaderGlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const HeaderGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.minHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    return FooterGlassPill(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class HeaderGlassIconPill extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const HeaderGlassIconPill({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.minHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderGlassPill(
      minHeight: minHeight,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double sigmaX;
  final double sigmaY;
  final double darkTintOpacity;
  final double lightTintOpacity;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.sigmaX = 25,
    this.sigmaY = 25,
    this.darkTintOpacity = 0.05,
    this.lightTintOpacity = 0.025,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.78, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: RepaintBoundary(
        child: GlassSurface(
          borderRadius: BorderRadius.circular(999),
          sigmaX: sigmaX,
          sigmaY: sigmaY,
          darkTintOpacity: darkTintOpacity,
          lightTintOpacity: lightTintOpacity,
          borderOpacity: 0.10,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class FooterGlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double sigmaX;
  final double sigmaY;

  const FooterGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.sigmaX = 32,
    this.sigmaY = 32,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassSurface(
        borderRadius: BorderRadius.circular(999),
        sigmaX: sigmaX,
        sigmaY: sigmaY,
        darkTintOpacity: 0.06,
        lightTintOpacity: 0.03,
        borderOpacity: 0.12,
        padding: padding,
        child: child,
      ),
    );
  }
}

class FooterGlassIconPill extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const FooterGlassIconPill({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return FooterGlassPill(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(18),
        sigmaX: 30,
        sigmaY: 30,
        borderOpacity: 0.12,
        darkTintOpacity: 0.07,
        lightTintOpacity: 0.035,
        child: Padding(
          padding: contentPadding ??
              const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 12),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleLarge,
                    child: title!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (content != null) ...[
                  Flexible(child: content!),
                ],
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
