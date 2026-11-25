#!/usr/bin/env bash
# EN: Fail unless the APK requests EXACTLY the permissions listed here. It reads the
#     built APK, not the source manifest, because a dependency can add a permission
#     during the build. An allowlist also catches permissions nobody thought to ban.
# FR: Échouer sauf si l'APK demande EXACTEMENT les permissions listées ici. Lit l'APK
#     construit, pas le manifeste source, car une dépendance peut ajouter une
#     permission pendant le build. Une liste permise attrape aussi les permissions que
#     personne n'avait pensé à interdire.
#
# Usage: tools/check_apk_permissions.sh path/to/app-release.apk
set -euo pipefail

apk="${1:?usage: $0 path/to/app.apk}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
aapt2="$(find "$sdk/build-tools" -name aapt2 -type f | sort -V | tail -1)"
[[ -x "$aapt2" ]] || { echo "aapt2 not found under $sdk" >&2; exit 2; }

expected="$(sort <<'LIST'
android.permission.POST_NOTIFICATIONS
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.VIBRATE
ca.veidimadur.snowbird_in_usa_tracker.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
LIST
)"
# EN: A failing aapt2 must not look like "no permissions".
# FR: Un échec d'aapt2 ne doit pas ressembler à « aucune permission ».
dump="$("$aapt2" dump permissions "$apk")"
actual="$(sed -n "s/^uses-permission[^:]*: name='\\([^']*\\)'.*/\\1/p" <<<"$dump" | sort -u)"

if [[ "$actual" != "$expected" ]]; then
  echo "Unexpected permissions (< expected, > found):" >&2
  diff <(echo "$expected") <(echo "$actual") >&2 || true
  exit 1
fi
echo "Permissions OK (no INTERNET)."
