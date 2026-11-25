#!/usr/bin/env bash
# EN: Fail unless every page the app opens answers 200, in both languages. Run before a
#     release: an installed app cannot change its links.
# FR: Échouer sauf si chaque page ouverte par l'appli répond 200, dans les deux langues. À
#     lancer avant une publication : une appli installée ne peut changer ses liens.
set -uo pipefail

pages="
/apps/days/report
/apps/days/request
/apps/days/status
/apps/days/roadmap
/apps/days/contribute
/apps/days/privacy
"
urls=("https://github.com/TACSAT/snowbird-in-usa-tracker")
for p in $pages; do
  for lang in en fr; do urls+=("https://teagarden.net$p?lang=$lang"); done
done

failed=0
for url in "${urls[@]}"; do
  code="$(curl -sSL -o /dev/null -m 20 -w '%{http_code}' "$url" 2>/dev/null)"
  if [[ "$code" == 200 ]]; then echo "ok   $url"; else echo "FAIL $code $url"; failed=1; fi
done
exit "$failed"
