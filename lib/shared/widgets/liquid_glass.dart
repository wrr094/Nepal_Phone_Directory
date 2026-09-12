import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';

class LiquidGlassScaffold extends StatelessWidget {
  const LiquidGlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: glass.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class LiquidGlassCard extends StatefulWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadii.card,
    this.blur = 12,
    this.opacity = 1,
    this.enableBlur = true,
    this.strong = false,
    this.onTap,
    this.semanticLabel,
    this.gradientOverlay = true,
    this.shadow = true,
    this.backgroundColor,
    this.bevelStrength = 0.24,
    this.pressedScale = 0.985,
    this.pressedOffset = 2.5,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final bool enableBlur;
  final bool strong;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool gradientOverlay;
  final bool shadow;
  final Color? backgroundColor;
  final double bevelStrength;
  final double pressedScale;
  final double pressedOffset;

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);
    final sourceColor =
        widget.backgroundColor ??
        (widget.strong ? glass.glassSurfaceStrong : glass.cardGlass);
    final baseColor = _multiplyAlpha(sourceColor, widget.opacity);
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.88);
    final lowlight =
        isDark
            ? Colors.black.withValues(alpha: 0.58)
            : glass.primaryAccent.withValues(alpha: 0.24);
    final bevelStrength = widget.bevelStrength.clamp(0.0, 1.4);
    final topGlowAlpha = (isDark ? 0.055 : 0.32) * bevelStrength;
    final midGlowAlpha = (isDark ? 0.010 : 0.08) * bevelStrength;
    final bottomShadeAlpha = (isDark ? 0.10 : 0.045) * bevelStrength;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      transform:
          Matrix4.identity()
            ..translateByDouble(
              0.0,
              _isPressed ? widget.pressedOffset : 0.0,
              0.0,
              1.0,
            )
            ..scaleByDouble(
              _isPressed ? widget.pressedScale : 1.0,
              _isPressed ? widget.pressedScale : 1.0,
              1.0,
              1.0,
            ),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: radius,
        border: Border.all(
          color:
              _isPressed
                  ? glass.primaryAccent.withValues(alpha: 0.42)
                  : glass.glassBorder,
          width: _isPressed ? 1.2 : 1,
        ),
        boxShadow:
            widget.shadow
                ? AppShadows.bevel(
                  highlight: highlight,
                  lowlight: lowlight,
                  pressed: _isPressed,
                  intensity: bevelStrength,
                )
                : null,
        gradient:
            widget.gradientOverlay
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    highlight.withValues(
                      alpha: _isPressed ? topGlowAlpha * 0.45 : topGlowAlpha,
                    ),
                    highlight.withValues(alpha: midGlowAlpha),
                    lowlight.withValues(
                      alpha:
                          _isPressed
                              ? bottomShadeAlpha * 0.65
                              : bottomShadeAlpha,
                    ),
                  ],
                  stops: const [0, 0.48, 1],
                )
                : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child:
            widget.enableBlur && widget.blur > 0
                ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blur,
                    sigmaY: widget.blur,
                  ),
                  child: _GlassCardSurface(
                    padding: widget.padding,
                    radius: widget.borderRadius,
                    highlight: highlight,
                    lowlight: lowlight,
                    pressed: _isPressed,
                    intensity: bevelStrength,
                    child: widget.child,
                  ),
                )
                : _GlassCardSurface(
                  padding: widget.padding,
                  radius: widget.borderRadius,
                  highlight: highlight,
                  lowlight: lowlight,
                  pressed: _isPressed,
                  intensity: bevelStrength,
                  child: widget.child,
                ),
      ),
    );
    if (widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: content),
      );
    }

    if (widget.semanticLabel != null) {
      content = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: content,
      );
    }

    return RepaintBoundary(
      child: Padding(padding: widget.margin ?? EdgeInsets.zero, child: content),
    );
  }
}

Color _multiplyAlpha(Color color, double opacity) {
  return color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
}

class _GlassCardSurface extends StatelessWidget {
  const _GlassCardSurface({
    required this.child,
    required this.padding,
    required this.radius,
    required this.highlight,
    required this.lowlight,
    required this.pressed,
    required this.intensity,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color highlight;
  final Color lowlight;
  final bool pressed;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _InnerBevelPainter(
                radius: radius,
                highlight: highlight,
                lowlight: lowlight,
                pressed: pressed,
                intensity: intensity,
              ),
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ],
    );
  }
}

class _InnerBevelPainter extends CustomPainter {
  const _InnerBevelPainter({
    required this.radius,
    required this.highlight,
    required this.lowlight,
    required this.pressed,
    required this.intensity,
  });

  final double radius;
  final Color highlight;
  final Color lowlight;
  final bool pressed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final level = intensity.clamp(0.0, 1.4);
    if (level <= 0) return;

    final topLeftColor = pressed ? lowlight : highlight;
    final bottomRightColor = pressed ? highlight : lowlight;
    final rect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = topLeftColor.withValues(
            alpha: (pressed ? 0.07 : 0.13) * level,
          );
    canvas.drawRRect(outerRRect, borderPaint);

    final edgeInset = pressed ? 2.3 : 1.5;
    final maxEdgeRadius = ((size.shortestSide - edgeInset * 2) / 2).clamp(
      0.0,
      radius,
    );
    final edgeRadius = (radius - edgeInset).clamp(0.0, maxEdgeRadius);
    final left = edgeInset;
    final top = edgeInset;
    final right = size.width - edgeInset;
    final bottom = size.height - edgeInset;
    final verticalMin = top + edgeRadius;
    final verticalMax = bottom - edgeRadius;
    final hasVerticalRoom = verticalMax >= verticalMin;
    final shortLeftBottom =
        hasVerticalRoom
            ? (top + size.height * 0.34).clamp(verticalMin, verticalMax)
            : (top + bottom) / 2;
    final shortRightTop =
        hasVerticalRoom
            ? (bottom - size.height * 0.34).clamp(verticalMin, verticalMax)
            : (top + bottom) / 2;

    final highlightPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pressed ? 0.8 : 1.1
          ..strokeCap = StrokeCap.round
          ..color = topLeftColor.withValues(
            alpha: (pressed ? 0.08 : 0.18) * level,
          );
    final shadowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pressed ? 0.95 : 1.05
          ..strokeCap = StrokeCap.round
          ..color = bottomRightColor.withValues(
            alpha: (pressed ? 0.10 : 0.14) * level,
          );

    final topLeftPath =
        Path()
          ..moveTo(left + edgeRadius, top)
          ..quadraticBezierTo(left, top, left, top + edgeRadius)
          ..moveTo(left + edgeRadius, top)
          ..lineTo(right - edgeRadius, top)
          ..moveTo(left, top + edgeRadius)
          ..lineTo(left, shortLeftBottom);

    final bottomRightPath =
        Path()
          ..moveTo(right - edgeRadius, bottom)
          ..quadraticBezierTo(right, bottom, right, bottom - edgeRadius)
          ..moveTo(right, shortRightTop)
          ..lineTo(right, bottom - edgeRadius)
          ..moveTo(left + edgeRadius, bottom)
          ..lineTo(right - edgeRadius, bottom);

    canvas.drawPath(topLeftPath, highlightPaint);
    canvas.drawPath(bottomRightPath, shadowPaint);

    final cornerShinePaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              highlight.withValues(alpha: (pressed ? 0.05 : 0.12) * level),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(radius * 0.72, radius * 0.72),
              radius: radius * 1.45,
            ),
          );
    canvas.drawRRect(outerRRect, cornerShinePaint);

    final bottomGlintPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              highlight.withValues(alpha: (pressed ? 0.03 : 0.07) * level),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width - radius * 0.45,
                size.height - radius * 0.35,
              ),
              radius: radius * 1.20,
            ),
          );
    canvas.drawRRect(outerRRect, bottomGlintPaint);
  }

  @override
  bool shouldRepaint(covariant _InnerBevelPainter oldDelegate) {
    return radius != oldDelegate.radius ||
        highlight != oldDelegate.highlight ||
        lowlight != oldDelegate.lowlight ||
        pressed != oldDelegate.pressed ||
        intensity != oldDelegate.intensity;
  }
}

class LiquidGlass3DCard extends StatelessWidget {
  const LiquidGlass3DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadii.card,
    this.blur = 10,
    this.enableBlur = true,
    this.strong = true,
    this.onTap,
    this.semanticLabel,
    this.backgroundColor,
    this.bevelStrength = 0.72,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final bool enableBlur;
  final bool strong;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? backgroundColor;
  final double bevelStrength;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      enableBlur: enableBlur,
      strong: strong,
      onTap: onTap,
      semanticLabel: semanticLabel,
      backgroundColor: backgroundColor,
      shadow: true,
      gradientOverlay: true,
      bevelStrength: bevelStrength,
      pressedScale: 0.97,
      pressedOffset: 2.8,
      child: child,
    );
  }
}

class BeveledGlassButton extends StatelessWidget {
  const BeveledGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foregroundColor = Colors.white,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color foregroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final buttonColor = color ?? glass.callButtonColor;

    return LiquidGlass3DCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 20,
      ),
      borderRadius: AppRadii.card,
      blur: 0,
      enableBlur: false,
      backgroundColor:
          onPressed == null
              ? glass.glassSurfaceStrong.withValues(alpha: 0.60)
              : buttonColor,
      bevelStrength: 0.90,
      onTap: onPressed,
      semanticLabel: semanticLabel ?? label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 30),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassSearchBar extends StatelessWidget {
  const GlassSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.panel,
      backgroundColor: glass.searchGlass,
      blur: 10,
      shadow: false,
      onTap: readOnly ? onTap : null,
      semanticLabel: readOnly ? hintText : null,
      child: AbsorbPointer(
        absorbing: readOnly,
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                onClear == null
                    ? null
                    : IconButton(
                      tooltip: 'Clear',
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                    ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(6),
        borderRadius: AppRadii.nav,
        backgroundColor: glass.bottomNavGlass,
        blur: 14,
        shadow: true,
        child: _DraggableGlassTabs(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ),
    );
  }
}

class _DraggableGlassTabs extends StatefulWidget {
  const _DraggableGlassTabs({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  State<_DraggableGlassTabs> createState() => _DraggableGlassTabsState();
}

class _DraggableGlassTabsState extends State<_DraggableGlassTabs> {
  double? _dragX;

  int get _visualIndex {
    final dragX = _dragX;
    if (dragX == null) return widget.selectedIndex;
    final itemWidth = _lastWidth / widget.destinations.length;
    return (dragX / itemWidth).floor().clamp(0, widget.destinations.length - 1);
  }

  double _lastWidth = 1;

  void _selectFromLocalPosition(Offset localPosition) {
    final itemWidth = _lastWidth / widget.destinations.length;
    final index = (localPosition.dx / itemWidth).floor().clamp(
      0,
      widget.destinations.length - 1,
    );
    _dragX = localPosition.dx.clamp(0, _lastWidth);
    if (index != widget.selectedIndex) {
      widget.onDestinationSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final itemCount = widget.destinations.length;
    final activeIndex = _visualIndex;

    return SizedBox(
      height: 70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastWidth = constraints.maxWidth;
          final itemWidth = constraints.maxWidth / itemCount;
          final selectorWidth = itemWidth - 6;
          final selectorLeft = (activeIndex * itemWidth) + 3;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() => _selectFromLocalPosition(details.localPosition));
            },
            onPanUpdate: (details) {
              setState(() => _selectFromLocalPosition(details.localPosition));
            },
            onPanEnd: (_) => setState(() => _dragX = null),
            onPanCancel: () => setState(() => _dragX = null),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: selectorLeft,
                  top: 5,
                  width: selectorWidth,
                  height: 58,
                  child: LiquidGlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: AppRadii.card,
                    blur: 12,
                    strong: true,
                    shadow: true,
                    backgroundColor: glass.glassSurfaceStrong,
                    child: const SizedBox.expand(),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < itemCount; index++)
                      Expanded(
                        child: _GlassTabItem(
                          destination: widget.destinations[index],
                          selected: index == activeIndex,
                          onTap: () => widget.onDestinationSelected(index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassTabItem extends StatelessWidget {
  const _GlassTabItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final color = selected ? glass.primaryAccent : glass.textSecondary;
    final icon =
        selected
            ? destination.selectedIcon ?? destination.icon
            : destination.icon;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            height: 1.1,
          ),
          child: IconTheme(
            data: IconThemeData(color: color, size: selected ? 25 : 23),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: icon,
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
