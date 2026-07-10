// EN: Application entry point. Responsibilities:
//     1. Initialise the Flutter binding (required before any plugin channel call).
//     2. Obtain the SharedPreferences singleton (async, resolved once at startup).
//     3. Wire the dependency graph: SharedPreferences → StorageService →
//        TripRepository → Provider → SnowBirdApp.
//     4. Hand off to runApp() — nothing else happens here.
//
//     Why resolve everything here rather than lazily inside widgets?
//     Because SharedPreferences.getInstance() is async, and resolving it at the
//     root avoids the "loading shimmer" anti-pattern where the trip list flashes
//     empty before data arrives. By the time the first widget builds, the data is
//     already in memory.
//
//     Privacy / security note: no analytics SDK, crash reporter, or network
//     initialisation happens here. The app makes zero outbound connections.
//
// FR: Point d'entrée de l'application. Responsabilités :
//     1. Initialiser le binding Flutter (requis avant tout appel de canal plugin).
//     2. Obtenir le singleton SharedPreferences (asynchrone, résolu une fois au
//        démarrage).
//     3. Câbler le graphe de dépendances : SharedPreferences → StorageService →
//        TripRepository → Provider → SnowBirdApp.
//     4. Déléguer à runApp() — rien d'autre ne se passe ici.
//
//     Pourquoi tout résoudre ici plutôt que paresseusement dans les widgets ?
//     Parce que SharedPreferences.getInstance() est asynchrone, et le résoudre à
//     la racine évite l'anti-patron « shimmer de chargement » où la liste des
//     séjours clignote vide avant l'arrivée des données. Quand le premier widget
//     se construit, les données sont déjà en mémoire.
//
//     Note confidentialité / sécurité : aucun SDK d'analyse, rapport de plantage
//     ou initialisation réseau ne se passe ici. L'appli n'effectue aucune
//     connexion sortante.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/notification_service.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';
import 'package:snowbird_in_usa_tracker/app.dart';

void main() async {
  // EN: Must be called before any plugin (SharedPreferences) can be accessed.
  //     The Flutter test runner calls this automatically; production apps must
  //     call it explicitly when main() is async.
  // FR: Doit être appelé avant tout accès à un plugin (SharedPreferences). Le
  //     runner de test Flutter l'appelle automatiquement ; les applis de
  //     production doivent l'appeler explicitement quand main() est asynchrone.
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final tripRepository = TripRepository(storage);

  // EN: Local notification stack. init() loads the timezone database and the
  //     plugin but requests NO permission — that happens only when the user
  //     creates their first alert. If init fails (e.g. an unsupported
  //     platform), the service degrades to a no-op and the rest of the app is
  //     unaffected.
  // FR: Pile de notifications locales. init() charge la base des fuseaux et le
  //     plugin mais ne demande AUCUNE permission — cela n'arrive que lorsque
  //     l'utilisateur crée sa première alerte. Si init échoue (p. ex. une
  //     plateforme non prise en charge), le service se dégrade en no-op et le
  //     reste de l'appli n'est pas affecté.
  final notificationService = NotificationService();
  await notificationService.init();

  final alertRepository = AlertRepository(
    storage,
    tripRepository,
    scheduler: notificationService,
  );

  runApp(
    // EN: .value constructors because the instances are already built above —
    //     Provider must not dispose them; the app's lifetime IS theirs.
    //     NotificationService is exposed under its AlertScheduler interface so
    //     widgets never see the plugin type.
    // FR: Constructeurs .value car les instances sont déjà construites
    //     ci-dessus — Provider ne doit pas les détruire ; leur durée de vie est
    //     celle de l'appli. NotificationService est exposé sous son interface
    //     AlertScheduler pour que les widgets ne voient jamais le type du plugin.
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TripRepository>.value(value: tripRepository),
        ChangeNotifierProvider<AlertRepository>.value(value: alertRepository),
        Provider<AlertScheduler>.value(value: notificationService),
      ],
      child: const SnowBirdApp(),
    ),
  );
}
