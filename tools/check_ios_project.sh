#!/usr/bin/env bash
# EN: Fail if the committed iOS project would not build cleanly in Xcode, or would drop
#     phones: Podfile.lock must match the Podfile (Xcode stops on a mismatch, while Flutter
#     silently repairs it), and the minimum iOS version must be the one written here, never
#     Xcode's moving "recommended" value.
# FR: Échouer si le projet iOS versionné ne se construirait pas proprement dans Xcode ou
#     exclurait des téléphones : Podfile.lock doit correspondre au Podfile (Xcode s'arrête
#     sur un écart, alors que Flutter le répare en silence), et la version minimale d'iOS
#     doit être celle écrite ici, jamais la valeur « recommandée » changeante de Xcode.
set -euo pipefail
cd "$(dirname "$0")/.."
minimum="15.0"
failed=0

want="$(shasum ios/Podfile | cut -d' ' -f1)"
have="$(sed -n 's/^PODFILE CHECKSUM: //p' ios/Podfile.lock)"
if [[ "$want" != "$have" ]]; then
  echo "Podfile.lock does not match Podfile: run 'pod install' in ios/ and commit it." >&2
  failed=1
fi

project=ios/Runner.xcodeproj/project.pbxproj
targets="$(sed -n 's/.*IPHONEOS_DEPLOYMENT_TARGET = \(.*\);.*/\1/p' "$project" | sort -u)"
if [[ "$targets" != "$minimum" ]]; then
  echo "Minimum iOS version is not $minimum everywhere in $project: ${targets//$'\n'/, }" >&2
  failed=1
fi
if ! grep -q "^platform :ios, '$minimum'" ios/Podfile; then
  echo "Minimum iOS version in ios/Podfile is not $minimum." >&2
  failed=1
fi
[[ "$failed" == 0 ]] && echo "iOS project OK (minimum iOS $minimum)."
exit "$failed"
