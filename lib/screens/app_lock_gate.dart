// EN: The optional app lock (WRK-11). When it is on, the app is covered at
//     start and every time it comes back from the background, until the
//     phone's own check passes (face, fingerprint or device code). The screens
//     underneath stay mounted, so nothing typed is lost, but they are hidden
//     from sight, touch and screen readers while locked.
//
//     The lock is set on "paused" or "hidden", never on "inactive": the
//     phone's own prompt makes the app inactive, and locking then would loop.
//     A check in progress is never interrupted by a second one.
// FR: Le verrouillage facultatif de l'appli (WRK-11). Lorsqu'il est activé,
//     l'appli est couverte au démarrage et chaque fois qu'elle revient de
//     l'arrière-plan, jusqu'à ce que la vérification du téléphone réussisse
//     (visage, empreinte ou code de l'appareil). Les écrans dessous restent en
//     place, afin que rien de saisi ne soit perdu, mais ils sont cachés à la
//     vue, au toucher et aux lecteurs d'écran tant que l'appli est verrouillée.
//
//     Le verrou s'enclenche sur « paused » ou « hidden », jamais sur
//     « inactive » : l'invite du téléphone rend l'appli inactive, et
//     verrouiller à ce moment-là tournerait en boucle. Une vérification en
//     cours n'est jamais interrompue par une deuxième.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:snowbird_in_usa_tracker/config/app_identity.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/services/device_auth.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';

// EN: Makes the device check available to the settings screen.
// FR: Rend la vérification de l'appareil accessible à l'écran des paramètres.
class AppLockScope extends InheritedWidget {
  final DeviceAuth auth;

  const AppLockScope({super.key, required this.auth, required super.child});

  // EN: The real check when no gate is above (a screen tested on its own).
  // FR: La vraie vérification quand aucune barrière n'est au-dessus (un écran
  //     testé seul).
  static DeviceAuth of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLockScope>()?.auth ??
      const LocalDeviceAuth();

  @override
  bool updateShouldNotify(AppLockScope oldWidget) => oldWidget.auth != auth;
}

class AppLockGate extends StatefulWidget {
  final DeviceAuth auth;
  final Widget child;

  const AppLockGate({super.key, required this.auth, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool? _locked;
  bool _checking = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // EN: Decided once, at start: turning the lock on in Settings does not
    //     lock the app there and then, only from the next start or return.
    // FR: Décidé une fois, au démarrage : activer le verrouillage dans les
    //     Paramètres ne verrouille pas l'appli sur-le-champ, seulement au
    //     prochain démarrage ou retour.
    if (_locked == null) {
      _locked = context.read<SettingsController>().appLock;
      if (_locked!) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _checking) return;
    final enabled = context.read<SettingsController>().appLock;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (enabled && _locked != true) {
        setState(() {
          _locked = true;
          _failed = false;
        });
      }
    } else if (state == AppLifecycleState.resumed && _locked == true) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_checking || !mounted) return;
    final strings = AppLocalizations.of(context);
    setState(() => _checking = true);
    final ok = await widget.auth.check(strings.lockReason(AppIdentity.name));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _locked = !ok;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked ?? false;
    return AppLockScope(
      auth: widget.auth,
      child: Stack(
        children: [
          ExcludeSemantics(
            excluding: locked,
            child: IgnorePointer(ignoring: locked, child: widget.child),
          ),
          if (locked)
            Positioned.fill(
              child: _LockScreen(
                checking: _checking,
                failed: _failed,
                onUnlock: _unlock,
              ),
            ),
        ],
      ),
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool checking;
  final bool failed;
  final VoidCallback onUnlock;

  const _LockScreen({
    required this.checking,
    required this.failed,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    strings.lockTitle(AppIdentity.name),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                if (failed)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        strings.lockFailed,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: Text(strings.lockUnlock),
                  onPressed: checking ? null : onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
