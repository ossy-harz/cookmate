import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final double elevation;

  const GlassCard({
    Key? key,
    required this.child,
    this.height,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.backgroundColor = Colors.white,
    this.elevation = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation > 0
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: elevation * 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

