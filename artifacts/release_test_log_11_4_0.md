# Musify 11.4.0+5 — release test log

Data: 28 settembre 2026  
Flavor: `githubRelease`  
Target: Samsung Galaxy S26 / Android 16 / ARM64-v8a

## Gate eseguiti

- `flutter gen-l10n`: completato;
- `flutter analyze`: nessuna issue;
- `flutter test`: 30 test superati;
- build: `flutter build apk --release --flavor github --target-platform android-arm64` completata;
- `apkanalyzer`: package `com.danilo.musify`, `versionName 11.4.0`, `versionCode 5`;
- runtime Flutter nell'APK: `lib/arm64-v8a/libapp.so` e `lib/arm64-v8a/libflutter.so`;
- `apksigner`: firma APK Signature Scheme v2 valida, un firmatario;
- certificato: `CN=Dan King`, SHA-256 `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`;
- bridge MediaStore Kotlin invariato, SHA-256 `2B3AC264C77DD0DB620589D674A8F382E14FD213DD7E98892CFB8CFD01356E21`;
- `piano_fasi.md`: confermato escluso da Git.

## Artefatto

- file: `artifacts/Musify-11.4.0-build5-samsung-s26-arm64.apk`;
- dimensione: 13.073.915 byte;
- SHA-256: `B008D78AE77430247E9053067C4A4B5EC94AA36CBFBC6FB39FE5F4C941D19AF9`.

## Copertura funzionale automatizzata

La suite include i gate preesistenti su permessi MediaStore, adapter locale, ricerca, CSV, versioning degli aggiornamenti e branding. Per questa release sono stati aggiunti controlli su:

- persistenza dell'ordine delle playlist personali in Hive;
- confronto del brano attivo per ID remoto e identità namespaced `local:`;
- eliminazione delle immagini duplicate dal mosaico;
- layout adattivo del mosaico 4/2/1.

## Nota build

Gradle ha emesso il warning non bloccante relativo al font `CupertinoIcons`, non referenziato negli asset finali. Le icone Material e Fluent richieste sono state incluse e ottimizzate tramite tree-shaking. Non sono emersi errori di compilazione.
