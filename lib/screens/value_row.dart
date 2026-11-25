// EN: A tappable "label / chosen value" row for dates and times. The value sits under
//     the label rather than beside it, so neither is squeezed at large text (NFR-5),
//     and any error is shown right where it must be fixed and announced to screen
//     readers. An optional value can be cleared with its own button.
// FR: Une rangée « étiquette / valeur choisie » pour dates et heures. La valeur se
//     place sous l'étiquette plutôt qu'à côté, pour qu'aucune ne soit écrasée en grand
//     texte (NFR-5), et toute erreur s'affiche là où la corriger et est annoncée aux
//     lecteurs d'écran. Une valeur facultative s'efface par son propre bouton.

import 'package:flutter/material.dart';

class ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? error;
  final String? clearTooltip;
  final VoidCallback? onClear;

  const ValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.clearTooltip,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(value, style: theme.textTheme.titleMedium),
          trailing: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: clearTooltip,
                  onPressed: onClear,
                ),
          onTap: onTap,
        ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EN: An icon as well as the colour: meaning never by colour alone.
                // FR: Une icône en plus de la couleur : jamais le sens par la couleur
                //     seule.
                Icon(
                  Icons.error_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
