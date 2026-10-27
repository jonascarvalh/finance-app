import 'package:flutter/material.dart';

/// Título de seção com ação opcional à direita ("Ver todas").
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.actionLabel, this.onAction, super.key});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (label != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
