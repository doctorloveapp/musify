<div align="center">
  <img src="assets/icons/musify_icon.png" width="128" alt="Icona Musify">

  # Musify

  **Streaming, playlist e musica locale in un unico player per Android.**

  [![Versione](https://img.shields.io/badge/versione-11.2.0-gold?style=flat-square)](https://github.com/doctorloveapp/musify/releases/latest)
  [![Android](https://img.shields.io/badge/Android-7--16-black?style=flat-square&logo=android)](https://github.com/doctorloveapp/musify)
  [![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
  [![Licenza](https://img.shields.io/github/license/doctorloveapp/musify?style=flat-square&color=D4AF37)](LICENSE)
  [![Release](https://img.shields.io/github/v/release/doctorloveapp/musify?style=flat-square&color=D4AF37)](https://github.com/doctorloveapp/musify/releases/latest)
</div>

## Panoramica

Musify è un'applicazione musicale Flutter per Android mantenuta da **Dan King**. Riunisce riproduzione in streaming, download offline, playlist personalizzate e file audio presenti sul dispositivo, offrendo la stessa coda e gli stessi controlli indipendentemente dall'origine del brano.

La release corrente usa il package Android `com.danilo.musify`, supporta Android da 7 a 16 e include un'integrazione MediaStore proprietaria progettata e collaudata su Android 16.

## Funzionalità

- ricerca e riproduzione di musica online;
- importazione della musica locale tramite Android MediaStore;
- scansione completa oppure selezione di una cartella indicizzata;
- libreria persistente dei brani importati;
- riproduzione di URI `content://` senza copiare o spostare i file dell'utente;
- playlist personalizzate e playlist miste online/locali;
- copertine playlist automatiche e persistenti, con mosaico da uno a quattro brani finché non viene scelta una cover manuale;
- riordino drag-and-drop dei brani con salvataggio immediato in Hive;
- aggiunta dei nuovi brani in testa alle playlist;
- Preferiti, Recenti, coda, Play e Shuffle condivisi fra tutte le sorgenti;
- aggiunta simultanea di tutti i brani di una playlist ai Preferiti;
- ascolto offline e download dei contenuti remoti;
- Android Auto con navigazione di Playlist, Preferiti e Musica locale;
- radio, testi, SponsorBlock ed equalizzatore con preset;
- statistiche e riepiloghi di ascolto;
- importazione di playlist Spotify;
- backup e ripristino dei dati trasferibili;
- Material UI, colori dinamici e tema nero;
- Home con richiamo all'ultima sessione di riproduzione e accesso rapido ai Preferiti;
- interfaccia localizzata, con rilevamento automatico della lingua del dispositivo;
- controllo aggiornamenti GitHub silenzioso e configurabile;
- nessuna pubblicità e nessun abbonamento.

## Musica locale

Il flusso è disponibile in:

`Impostazioni > Musica locale`

Da questa sezione è possibile:

1. avviare a schermo intero una scansione completa della raccolta audio;
2. selezionare a schermo intero una singola cartella fra quelle indicizzate da MediaStore;
3. cercare per titolo, nome file, artista, album, cartella o percorso e selezionare i file da importare;
4. aprire **Visualizza brani importati**;
5. riprodurre un brano, aggiungerlo ai Preferiti o inserirlo in una playlist;
6. rimuovere un riferimento dalla libreria senza cancellare il file fisico.

Al termine di un'importazione riuscita, la schermata dei risultati si chiude automaticamente e torna alla pagina **Musica locale**.

Ogni file riceve un'identità stabile e namespaced:

```text
local:<volume-media-store>:<media-store-id>
```

Questo formato impedisce collisioni con gli identificativi dei servizi online. I riferimenti vengono salvati nel box Hive `localLibrary`; Musify non elimina né modifica il file audio originale.

### Permessi Android

| Versione | API | Permesso richiesto |
| --- | ---: | --- |
| Android 7–12L | 24–32 | `READ_EXTERNAL_STORAGE` |
| Android 13–16 | 33–36 | `READ_MEDIA_AUDIO` |

Il permesso viene richiesto soltanto in seguito a un'azione esplicita dell'utente. La query MediaStore viene eseguita esclusivamente dopo la conferma del grant sia nel codice Dart sia nel bridge Kotlin.

## Android Auto

Musify espone un `MediaBrowserService` attraverso `audio_service` e rende navigabili dal sistema dell'auto tre categorie principali:

- Playlist;
- Preferiti;
- Musica locale.

Le voci restituiscono elementi browsable o playable standard, supportano i comandi della sessione multimediale e la ricerca vocale. La musica locale è mostrata soltanto quando il relativo permesso è già stato concesso sul telefono; Android Auto non tenta di aprire dialog di autorizzazione sul cruscotto.

Il Manifest include il descrittore automotive `<uses name="media"/>`, il servizio media esportato, il receiver dei pulsanti multimediali e un'icona vettoriale monocromatica per l'interfaccia dell'auto.

## Aggiornamenti

Il controllo aggiornamenti consulta esclusivamente:

```text
https://api.github.com/repos/doctorloveapp/musify/releases/latest
```

Il comportamento è intenzionalmente non invasivo:

- nessun popup viene mostrato all'avvio;
- se **Controllo aggiornamenti automatici** è disabilitato non viene eseguita alcuna richiesta;
- il tag della release viene confrontato semanticamente con la versione installata;
- quando è disponibile una versione più recente compare soltanto un indicatore discreto nelle Impostazioni;
- il tap sull'indicatore apre la release nel repository ufficiale di questa distribuzione.

## Requisiti di sviluppo

- Flutter `3.47.2`;
- Dart `3.13.2`;
- FVM consigliato;
- Android SDK 36;
- Java 17;
- NDK `28.2.13676358` per la build Android configurata.

Il vincolo Dart del progetto è:

```yaml
sdk: ">=3.13.0 <4.0.0"
flutter: ^3.47.2
```

## Configurazione con FVM

```bash
git clone https://github.com/doctorloveapp/musify.git
cd musify
fvm install 3.47.2
fvm use 3.47.2
fvm flutter pub get
fvm flutter gen-l10n
```

Avvio del flavor GitHub:

```bash
fvm flutter run --flavor github
```

Avvio del flavor F-Droid:

```bash
fvm flutter run --flavor fdroid
```

## Build

Build APK GitHub:

```bash
fvm flutter build apk --release --flavor github
```

Build APK F-Droid:

```bash
fvm flutter build apk --release --flavor fdroid
```

### Firma della release

Le chiavi private non fanno parte del repository. Per una build release locale creare `android/key.properties` con questa struttura:

```properties
storeFile=app/key.jks
storePassword=<password-keystore>
keyPassword=<password-chiave>
keyAlias=<alias>
```

Collocare quindi il proprio keystore in `android/app/key.jks`. Entrambi i file sono esclusi dal controllo versione e non devono essere pubblicati.

## Qualità e test

Prima di creare una release eseguire:

```bash
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm flutter build apk --release --flavor github
fvm flutter build apk --release --flavor fdroid
```

La release `11.2.0+3` è stata validata lato build con:

- analisi statica senza errori;
- 22 test automatici superati;
- build release del flavor GitHub;
- verifica della firma APK;
- verifica del Manifest compilato, dei permessi e del servizio Android Auto;
- baseline MediaStore e riproduzione locale già superata su Samsung Galaxy S26, One UI 8.5, Android 16; il nuovo smoke test UI 11.2 resta da eseguire sul dispositivo.

## Architettura della musica locale

```text
UI importazione
      │
      ▼
LocalAudioService ─────► Hive localLibrary
      │
      ├────► LocalTrackAdapter ─────► modello brano Musify
      │
      ▼
LocalAudioDataSource
      │
      ▼
Bridge Kotlin ─────► ContentResolver / MediaStore
```

Componenti principali:

| Percorso | Responsabilità |
| --- | --- |
| `lib/services/local_audio_service.dart` | permessi, scansione, importazione e persistenza |
| `lib/services/local_audio_data_source.dart` | contratto astratto della sorgente locale |
| `lib/services/media_store_audio_data_source.dart` | comunicazione con il bridge Android |
| `lib/utilities/local_track_adapter.dart` | conversione dei record MediaStore |
| `lib/utilities/song_source.dart` | origine e identità dei brani |
| `lib/services/audio_service.dart` | player, coda, background e Android Auto |
| `lib/screens/local_audio_import_page.dart` | accesso e riepilogo della libreria locale |
| `lib/screens/local_audio_scan_page.dart` | scansione full-screen, ricerca, selezione e importazione |
| `lib/screens/user_songs_page.dart` | elenco dei brani importati |
| `lib/services/playlists_manager.dart` | ordine playlist e metadati delle cover generate |
| `lib/utilities/playlist_cover.dart` | selezione persistente degli artwork del mosaico |
| `lib/screens/playlist_reorder_page.dart` | riordino drag-and-drop dei brani |

Il player è basato su `audio_service` e `just_audio`. Un adapter converte i record locali nel contratto dati già utilizzato dall'app, evitando percorsi separati per coda, playlist e Preferiti.

## Compatibilità

| Configurazione | Valore |
| --- | --- |
| Package GitHub | `com.danilo.musify` |
| Package F-Droid | `com.danilo.musify.fdroid` |
| `minSdk` | 24 — Android 7 |
| `compileSdk` | 36 — Android 16 |
| `targetSdk` | 36 — Android 16 |
| Versione | `11.2.0+3` |

## Download e segnalazioni

- [Scarica l'ultima release](https://github.com/doctorloveapp/musify/releases/latest)
- [Segnala un problema](https://github.com/doctorloveapp/musify/issues)
- [Proponi una modifica](https://github.com/doctorloveapp/musify/pulls)

Quando viene segnalato un problema relativo alla musica locale, indicare versione Android, produttore del dispositivo, stato del permesso audio e passaggi necessari a riprodurre l'errore. Non pubblicare path personali o file audio protetti.

## Manutenzione

**Dan King**<br>
GitHub: [@doctorloveapp](https://github.com/doctorloveapp)<br>
Repository: [doctorloveapp/musify](https://github.com/doctorloveapp/musify)

## Licenza

Musify è distribuito secondo i termini della [GNU General Public License v3.0](LICENSE). Le distribuzioni e le modifiche devono rispettare la GPL, rendere disponibile il codice sorgente corrispondente e conservare gli avvisi di copyright e licenza presenti nei file sorgente e nelle dipendenze.

## Esclusione di responsabilità

Musify non ospita né distribuisce contenuti audio protetti. I brani online, i file locali, i marchi e i relativi metadati appartengono ai rispettivi titolari. L'utente è responsabile dell'utilizzo dell'app nel rispetto delle leggi applicabili, del diritto d'autore e delle condizioni dei servizi utilizzati.

Il software viene fornito senza garanzie. Il manutentore non incoraggia la violazione del copyright e non assume responsabilità per usi impropri dell'applicazione o delle integrazioni di terze parti.
