# Musify 11.4.1+2006 — release test log

Data: 7 ottobre 2026  
Flavor: `githubRelease`  
Target: Samsung Galaxy S26 / Android 16 / ARM64-v8a

## Ambito della patch

- aggiornato lo User-Agent del client WEB YouTube a Chrome `149.0.7827.232`;
- aggiornato `browserVersion` a `149.0.7827.232`;
- aggiornato il client Innertube WEB a `2.20260708.00.00`;
- nessuna modifica a endpoint, token, API key, struttura delle richieste o gestione degli errori;
- versioning applicazione aggiornato a `11.4.1+2006` per superare il `versionCode 2005` della precedente build ARM64 pubblicata.

## Gate eseguiti

- `flutter analyze`: nessuna issue;
- `flutter test`: 30 test superati;
- smoke test reale YouTube, ricerca video: superato;
- smoke test reale YouTube, paginazione playlist oltre 100 brani: superato;
- build `flutter build apk --release --flavor github --target-platform android-arm64`: completata;
- `apkanalyzer`: package `com.danilo.musify`, `versionName 11.4.1`, `versionCode 2006`;
- runtime Flutter nell'APK: `lib/arm64-v8a/libapp.so` e `lib/arm64-v8a/libflutter.so`;
- `apksigner`: firma APK Signature Scheme v2 valida, un firmatario;
- certificato: `CN=Dan King`, SHA-256 `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`;
- bridge MediaStore Kotlin invariato, SHA-256 `2B3AC264C77DD0DB620589D674A8F382E14FD213DD7E98892CFB8CFD01356E21`.

## Artefatto

- file: `artifacts/Musify-11.4.1-build2006-samsung-s26-arm64.apk`;
- dimensione: 13.074.115 byte;
- SHA-256: `6DA7316DA4F36BA3FE9410D6FD0098430E65F8308699AFF4440F626C7F428F66`.

## Note

Gradle ha emesso il warning non bloccante relativo al font `CupertinoIcons`, non incluso negli asset finali. Le icone Material e Fluent richieste sono state incluse e ottimizzate tramite tree-shaking. Non sono emersi errori di compilazione.

La validazione hardware della patch `11.4.1+2006` resta da eseguire sul Samsung Galaxy S26. L'asset GitHub con `versionCode 6` deve essere sostituito con l'APK correttivo.
