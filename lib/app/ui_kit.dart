import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import 'demo_store.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(
        Icons.sports_soccer,
        color: scheme.onPrimary,
        size: size * .54,
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.name,
    this.photoBase64,
    this.size = 44,
    this.color,
    super.key,
  });

  final String name;
  final String? photoBase64;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ImageProvider? image;
    final photo = photoBase64;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } on FormatException {
        image = null;
      }
    }
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color ?? scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              initials.isEmpty ? 'HE' : initials,
              style: TextStyle(
                fontSize: size * .29,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class LocalDemoBadge extends StatelessWidget {
  const LocalDemoBadge({
    this.label = 'Demo · datos locales',
    this.icon = Icons.phone_android_outlined,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      );
}

class PageBody extends StatelessWidget {
  const PageBody({
    required this.children,
    this.maxWidth = 1000,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? 18.0 : 28.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 36),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 38,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 11),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      );
}

class DemoPanel extends StatelessWidget {
  const DemoPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: .36,
                ),
          ),
        ),
        child: child,
      );
}

String formatDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String initialsFor(String text) {
  final parts = text.trim().split(RegExp(r'\s+'));
  return parts
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
}

String matchStatusLabel(DemoMatchStatus status) => switch (status) {
      DemoMatchStatus.proposed => 'Pendiente',
      DemoMatchStatus.accepted => 'Confirmado',
      DemoMatchStatus.declined => 'Rechazado',
    };
