# Musify 11.0.0+2 — log di verifica release

Data: 9 settembre 2026  
Toolchain: Flutter 3.47.2, Dart 3.13.2, Android compile/target SDK 36  
Workspace: SDK isolato tramite FVM; SDK Flutter globale non modificato.

## Verifiche automatiche

| Verifica | Risultato |
| --- | --- |
| `dart format` sui file modificati | Superata |
| `flutter gen-l10n` | Superata |
| `flutter analyze` | Superata, 0 problemi |
| `flutter test` | Superata, 19 test |
| `flutter build apk --release --flavor github` | Superata, APK 30.8 MB |
| `flutter build apk --release --flavor fdroid` | Superata, APK 31.2 MB |
| `apksigner verify` GitHub/F-Droid | Superata |
| `aapt2 dump badging` | Superata |
| `aapt2 dump xmltree AndroidManifest.xml` | Superata |

La suite comprende il gate dei permessi MediaStore, il contenimento degli errori di query, mapping e round-trip `MediaItem` dei file locali, merge/riconciliazione Hive, risoluzione locale e confronto SemVer dei tag GitHub.

## APK GitHub finale

- File: `Musify-11.0.0-build2-stable.apk`
- Package: `com.danilo.musify`
- Versione: `11.0.0` (`versionCode 2`)
- Compatibilità dichiarata: minSdk 24, targetSdk 36
- SHA-256: `27C5B79052A9662E0073167E8EA921075490C6AEC6F8B87BC678FD65A9B34CE1`
- Firma APK Signature Scheme v2: valida
- Certificato: `CN=Dan King, OU=Development, O=Dan King, STREET="via Roma, 1", L=Roma, ST=Roma, C=IT`
- SHA-256 certificato: `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`

## APK F-Droid

- File: `Musify-11.0.0-build2-fdroid.apk`
- Package: `com.danilo.musify.fdroid`
- Versione: `11.0.0` (`versionCode 2`)
- SHA-256: `05536D6B177F97C777EE0A44F72D21A3E39A39DB1BE4C30AC1FB5B78B906EAB7`
- Firma: valida

## Verifica packaging Android Auto

Il Manifest compilato dell'APK GitHub contiene:

- servizio esportato `com.ryanheise.audioservice.AudioService`;
- intent `android.media.browse.MediaBrowserService`;
- metadata `com.google.android.gms.car.application` verso il descrittore automotive;
- metadata `androidx.car.app.TintableAttributionIcon` verso l'icona vettoriale monocromatica;
- foreground service type `mediaPlayback` e receiver dei media button.

Il descrittore sorgente automotive dichiara `<uses name="media"/>`. Il resource linking della build release è riuscito e il riferimento compilato è presente nel Manifest.

## Gate hardware

Risultato fornito dal collaudo sul Samsung Galaxy S26, One UI 8.5, Android 16: integrazione locale tramite bridge Kotlin stabile, performante e senza crash. Durante questa build conclusiva `adb devices -l` non mostrava dispositivi collegati; la nuova UI “Brani importati” e la superficie Android Auto devono quindi ricevere un ultimo smoke test sul telefono/auto o Desktop Head Unit prima della distribuzione pubblica.

Nota non bloccante: Flutter segnala cinque aggiornamenti di dipendenze non compatibili con i vincoli correnti; non sono stati forzati in questa release stabile per evitare una migrazione estranea al ciclo verificato.
