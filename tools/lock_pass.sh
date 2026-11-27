#!/usr/bin/env bash
# EN: Proves the real app-lock check on an iOS simulator: enrols Face ID, runs
#     integration_test/lock_pass_test.dart, and sends a matching face every two
#     seconds while it waits. Usage: tools/lock_pass.sh <simulator udid>
# FR: Prouve la vraie vérification du verrouillage sur un simulateur iOS :
#     enrôle Face ID, lance integration_test/lock_pass_test.dart, et envoie un
#     visage correspondant toutes les deux secondes pendant l'attente.
#     Usage : tools/lock_pass.sh <udid du simulateur>
set -euo pipefail
udid="${1:?usage: $0 <simulator udid>}"
cd "$(dirname "$0")/.."
xcrun simctl spawn "$udid" notifyutil -s com.apple.BiometricKit.enrollmentChanged '1'
xcrun simctl spawn "$udid" notifyutil -p com.apple.BiometricKit.enrollmentChanged
( while true; do
    sleep 2
    xcrun simctl spawn "$udid" notifyutil -p com.apple.BiometricKit_Sim.pearl.match >/dev/null 2>&1 || true
  done ) &
matcher=$!
trap 'kill $matcher 2>/dev/null || true' EXIT
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/lock_pass_test.dart -d "$udid"
