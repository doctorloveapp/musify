# Musify 11.4.1+6 — release test log

Data: 7 ottobre 2026  
Flavor: `githubRelease`  
Target: Samsung Galaxy S26 / Android 16 / ARM64-v8a

## Ambito della patch

- aggiornato lo User-Agent del client WEB YouTube a Chrome `149.0.7827.232`;
- aggiornato `browserVersion` a `149.0.7827.232`;
- aggiornato il client Innertube WEB a `2.20260708.00.00`;
- nessuna modifica a endpoint, token, API key, struttura delle richieste o gestione degli errori;
- versioning applicazione aggiornato a `11.4.1+6`.

## Gate eseguiti

- `flutter analyze`: nessuna issue;
- `flutter test`: 30 test superati;
- smoke test reale YouTube, ricerca video: superato;
- smoke test reale YouTube, paginazione playlist oltre 100 brani: superato;
- build `flutter build apk --release --flavor github --target-platform android-arm64`: completata;
- `apkanalyzer`: package `com.danilo.musify`, `versionName 11.4.1`, `versionCode 6`;
- runtime Flutter nell'APK: `lib/arm64-v8a/libapp.so` e `lib/arm64-v8a/libflutter.so`;
- `apksigner`: firma APK Signature Scheme v2 valida, un firmatario;
- certificato: `CN=Dan King`, SHA-256 `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`;
- bridge MediaStore Kotlin invariato, SHA-256 `2B3AC264C77DD0DB620589D674A8F382E14FD213DD7E98892CFB8CFD01356E21`.

## Artefatto

- file: `artifacts/Musify-11.4.1-build6-samsung-s26-arm64.apk`;
- dimensione: 13.074.111 byte;
- SHA-256: `C36DE7813D63C1A77BFAF6E8121CB42357E4B0BC801E4F7A12007BC6023D7301`.

## Note

Gradle ha emesso il warning non bloccante relativo al font `CupertinoIcons`, non incluso negli asset finali. Le icone Material e Fluent richieste sono state incluse e ottimizzate tramite tree-shaking. Non sono emersi errori di compilazione.

La validazione hardware della patch `11.4.1+6` resta da eseguire sul Samsung Galaxy S26. La release GitHub non è stata pubblicata durante questa attività.
