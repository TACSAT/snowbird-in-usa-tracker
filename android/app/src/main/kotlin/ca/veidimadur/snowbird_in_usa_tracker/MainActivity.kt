package ca.veidimadur.snowbird_in_usa_tracker

import io.flutter.embedding.android.FlutterFragmentActivity

// EN: A FragmentActivity, because the optional app lock (WRK-11) shows the
//     phone's own biometric prompt, which needs one (local_auth).
// FR: Une FragmentActivity, car le verrouillage facultatif de l'appli (WRK-11)
//     affiche l'invite biométrique du téléphone, qui en exige une (local_auth).
class MainActivity : FlutterFragmentActivity()
