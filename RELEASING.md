# Releasing SnowBird

Author: Veiðimaður - veidimadur.ca

## Before the first release (owner)

- [ ] Set `feedbackUrl` and `donateUrl` in `lib/config/app_links.dart` (both are placeholders).
- [ ] Supply an app icon (1024 x 1024 px) for iOS and Android.
- [ ] Review the French wording.
- [ ] Review `PRIVACY.md`, then publish it at a public URL for both store listings.
- [ ] Create and back up the Android upload key (below).
- [ ] Apple Developer Program and Google Play Developer accounts.
- [ ] Store screenshots, led by the US Presence Record.
- [ ] Complete the device checklist (below).

## Android upload key

Run this yourself, outside the repository. `keytool` prompts for the passwords.

```bash
mkdir -p ~/keys
keytool -genkeypair -v -keystore ~/keys/snowbird-upload.jks \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

Back the file up in two places, and keep its password in a password manager. Then create
`android/key.properties` (gitignored, never commit it):

```properties
storeFile=/absolute/path/to/snowbird-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

This repository sits in an iCloud-synced folder, so `key.properties` would sync too. If you
do not want that, keep the real file elsewhere and symlink it.

## Every release

1. Raise `version:` in `pubspec.yaml` (both the name and the build number).
2. `dart format lib test && flutter analyze && flutter test`
3. `flutter build appbundle --release` and `flutter build ipa --release`
4. `flutter build apk --release`, then
   `tools/check_apk_permissions.sh build/app/outputs/flutter-apk/app-release.apk`
5. Confirm the APK is not signed with the debug key:
   `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`
   must not show `CN=Android Debug`.

## Device checklist (iPhone, iPad, Android)

1. First alert: permission prompt appears; the alert arrives with the app closed and open.
2. Deny permission, then switch the alert off and on.
3. Change the time zone and reopen; a delivered alert stays in the tray.
4. Share the PDF, a multi-page PNG and the CSV, and print. iPad especially.
5. Largest text with VoiceOver and TalkBack, in English and French; open a date picker.
6. Run a what-if, then save it as a planned trip.
7. Upgrade over the previous version and confirm the old trips load.
8. Restore a phone backup and confirm the trips and alerts return.
