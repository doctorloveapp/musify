# Musify 11.2.0+3 — log di verifica

Data: 10 settembre 2026

## Controlli eseguiti

- `flutter gen-l10n`: completato.
- `dart analyze`: completato, nessuna issue.
- `flutter test --no-pub`: 22 test superati.
- `flutter build apk --release --flavor github --no-pub`: completato.
- Verifica manifest APK con `apkanalyzer`: `com.danilo.musify`, `versionName 11.2.0`, `versionCode 3`.
- Verifica firma con `apksigner`: valida con APK Signature Scheme v2, un firmatario, certificato `CN=Dan King`.
- Confronto firma 11.0/11.2: stesso digest certificato SHA-256 `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`, quindi upgrade Android in-place compatibile.
- Verifica integrità bridge Kotlin: SHA-256 invariato `2B3AC264C77DD0DB620589D674A8F382E14FD213DD7E98892CFB8CFD01356E21`.

## APK

- File: `Musify-11.2.0-build3-stable.apk`
- Dimensione: 32.783.209 byte
- SHA-256: `8E992F61DE04DF9419720364C1ADDBD7E85993379192218DDD50A523B0F7CA20`

## Gate hardware ancora richiesto

La baseline MediaStore/player è già stata superata su Samsung Galaxy S26, One UI 8.5, Android 16. Per la release 11.2 resta lo smoke test delle nuove superfici UI: card Ultima riproduzione, mosaici persistenti, drag-and-drop, scansione full-screen, ricerca, chiusura dopo import e rimozione non distruttiva.
