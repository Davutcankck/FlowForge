import 'package:flutter/material.dart';

/// Tek elle kullanıma uygun, büyük ve erişilebilir soru seçim kartı (SDD 6.3).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSecondary
        ? colorScheme.surfaceContainerLow
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isSecondary
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight:
                              isSecondary ? FontWeight.w500 : FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
