import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: foregroundColor ?? theme.appBarTheme.foregroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            )
          : null),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

