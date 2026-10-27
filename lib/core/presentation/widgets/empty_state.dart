import 'package:flutter/material.dart';

/// Mensagem amigável para listas/gráficos sem dados.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  /// Versão menor, para uso dentro de cartões.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = message;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 20 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 48 : 64,
            height: compact ? 48 : 64,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: compact ? 24 : 30),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium,
          ),
          if (text != null) ...[
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
