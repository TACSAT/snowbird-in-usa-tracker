// EN: Placeholder for the primary Trip List screen. This file scaffolds the
//     widget and wires it to TripRepository so that main.dart compiles and the app
//     launches. The full implementation — trip cards, FAB, delete swipe, empty
//     state, and the day-count summary bar — belongs to build step 2 (PLAN.md).
//
//     Keeping this as a real widget (not a bare Container) means we can already
//     verify Provider wiring, theme colours, and localisation loading in the
//     running app before any feature UI is built.
//
// FR: Espace réservé pour l'écran principal de liste des séjours. Ce fichier
//     structure le widget et le connecte à TripRepository pour que main.dart compile
//     et que l'appli se lance. L'implémentation complète — cartes de séjour, FAB,
//     glissement pour supprimer, état vide et barre de résumé des jours — appartient
//     à l'étape 2 de construction (PLAN.md).
//
//     Conserver un vrai widget (et non un simple Container) permet de vérifier dès
//     maintenant le câblage Provider, les couleurs du thème et le chargement de la
//     localisation dans l'appli en cours d'exécution, avant que toute interface de
//     fonctionnalité soit construite.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // EN: Read the repository count just to confirm Provider wiring is live.
    //     Step 2 will replace this with a full list/empty-state widget.
    // FR: Lire le nombre de séjours du dépôt uniquement pour confirmer que le
    //     câblage Provider est actif. L'étape 2 remplacera ceci par un widget de
    //     liste/état vide complet.
    final count = context.watch<TripRepository>().tripCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnowBird'),
        centerTitle: false,
        actions: [
          // EN: Entry point to the user's alerts. The outlined (not filled)
          //     bell mirrors the product stance: alerts exist only if the user
          //     creates them.
          // FR: Point d'entrée vers les alertes de l'utilisateur. La cloche en
          //     contour (non pleine) reflète la position du produit : les
          //     alertes n'existent que si l'utilisateur les crée.
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: AppLocalizations.of(context).alertsTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AlertsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_land_rounded, size: 64),
            const SizedBox(height: 16),
            Text(
              'Architecture ready — $count trip(s) in storage.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Full trip list UI is built in step 2.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      // EN: FAB is declared now so the scaffold shape is correct from the start
      //     and step 2 can simply replace the onPressed body.
      // FR: Le FAB est déclaré maintenant pour que la forme du scaffold soit
      //     correcte dès le départ et que l'étape 2 puisse simplement remplacer
      //     le corps onPressed.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add trip',
        onPressed: () {
          // TODO(step-2): open AddTripScreen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
