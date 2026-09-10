# Musify 11.3.1+4 — log di verifica

Data: 10 settembre 2026

## Controlli eseguiti

- `flutter gen-l10n`: completato.
- `flutter analyze --no-pub`: completato, nessuna issue.
- `flutter test --no-pub`: 26 test superati.
- Test contesto Home: soltanto una playlist personale esistente sostituisce l'ultimo contesto persistito; brani singoli e playlist non personali lo lasciano invariato.
- Test CSV: round-trip con virgole, virgolette, Unicode e newline; formato Spotify minimo; nome file sicuro.
- `flutter build apk --release --flavor github --no-pub`: completato.
- Verifica Manifest con `apkanalyzer`: `com.danilo.musify`, `versionName 11.3.1`, `versionCode 4`.
- Verifica firma con `apksigner`: APK Signature Scheme v2 valida, un firmatario, certificato `CN=Dan King`.
- Continuità firma: digest certificato SHA-256 `8a18e89d96da5a7334e72da693bfc97c21f27664e9211b42d3addbee08f890fe`, identico alle release 11.0/11.2.
- Integrità bridge Kotlin: SHA-256 invariato `2B3AC264C77DD0DB620589D674A8F382E14FD213DD7E98892CFB8CFD01356E21`.

## APK

- File: `Musify-11.3.1-build4-stable.apk`
- Dimensione: 32.785.237 byte
- SHA-256: `3B534E1E9A85A370AFA59E5A5A6D3DC426481F73C20EBCFB5CB3A9F8EBC66FED`

## Gate hardware

La release 11.2 e la baseline MediaStore/player sono state validate su Samsung Galaxy S26, One UI 8.5, Android 16. La 11.3.1 mantiene intatto il bridge nativo; resta consigliato uno smoke test sul dispositivo per la nuova card **Ultima Playlist** e per l'invio/reimportazione del file CSV tramite Share Sheet.
