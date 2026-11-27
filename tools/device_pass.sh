#!/usr/bin/env bash
# EN: Runs the Step 7 device pass (integration_test/device_pass_test.dart) on one
#     simulator, emulator or phone, and leaves screenshots and export files in
#     build/device_pass/. Usage: tools/device_pass.sh <device id>
#     (see `flutter devices`). It clears the app's data on that device first.
# FR: Lance la vérification sur appareil de l'étape 7 sur un simulateur, un
#     émulateur ou un téléphone, et laisse captures et fichiers d'export dans
#     build/device_pass/. Usage : tools/device_pass.sh <id de l'appareil>
#     (voir `flutter devices`). Elle efface d'abord les données de l'appli sur
#     cet appareil.
set -euo pipefail
device="${1:?usage: $0 <device id>}"
cd "$(dirname "$0")/.."
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/device_pass_test.dart \
  -d "$device"
ls build/device_pass | wc -l | xargs echo "files in build/device_pass:"
