<div align="center">
  <img src="assets/icons/musify_icon.png" width="128" alt="Icona Musify">

  # Musify

  **Streaming, playlist e musica locale in un unico player per Android.**

  [![Versione](https://img.shields.io/badge/versione-11.5.2-gold?style=flat-square)](https://github.com/doctorloveapp/musify/releases/latest)
  [![Android](https://img.shields.io/badge/Android-7--16-black?style=flat-square&logo=android)](https://github.com/doctorloveapp/musify)
  [![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
  [![Licenza](https://img.shields.io/github/license/doctorloveapp/musify?style=flat-square&color=D4AF37)](LICENSE)
  [![Release](https://img.shields.io/github/v/release/doctorloveapp/musify?style=flat-square&color=D4AF37)](https://github.com/doctorloveapp/musify/releases/latest)
</div>

## Panoramica

Questo repository è un **fork indipendente** di [gokadzev/Musify](https://github.com/gokadzev/Musify), il progetto creato da **Valeri Gokadze** con il contributo della sua comunità. Questa distribuzione è mantenuta da **Dan King** nel repository [doctorloveapp/musify](https://github.com/doctorloveapp/musify). Riunisce riproduzione in streaming, download offline, playlist personalizzate e file audio presenti sul dispositivo, offrendo la stessa coda e gli stessi controlli indipendentemente dall'origine del brano.

La release corrente usa il package Android `com.danilo.musify`, supporta Android da 7 a 16 e include un'integrazione MediaStore proprietaria progettata e collaudata su Android 16.

## Credits e origine del fork

Il merito del progetto Musify originale, della sua architettura e delle funzionalità da cui questo fork deriva spetta a **Valeri Gokadze** e ai [contributori del progetto originale](https://github.com/gokadzev/Musify/graphs/contributors). Questo fork conserva gli avvisi di copyright nei sorgenti e il testo originale della licenza GPL-3.0. L'attribuzione aggiuntiva è documentata anche in [NOTICE.md](NOTICE.md).

Le principali divergenze di questo fork sono la libreria audio locale tramite MediaStore e bridge Kotlin, le playlist miste e le copertine dinamiche, il riordino drag-and-drop, la condivisione/importazione CSV, il browser musicale per Android Auto, la Home centrata sull'ultima playlist personale e il controllo aggiornamenti discreto riferito a questo repository.

**Supporto e segnalazioni di questo fork:** aprire [issue](https://github.com/doctorloveapp/musify/issues) o [pull request](https://github.com/doctorloveapp/musify/pulls) esclusivamente su `doctorloveapp/musify`. Per contattare direttamente il manutentore: [doctorloveapp@gmail.com](mailto:doctorloveapp@gmail.com). Il repository originale non è il canale di assistenza per questa distribuzione.

## Funzionalità

### Riproduzione e catalogo

- ricerca e riproduzione di musica online tramite un player basato su `audio_service` e `just_audio`;
- coda condivisa, Play, Pausa, Shuffle, Repeat, Recenti e controlli multimediali di sistema;
- download e ascolto offline dei contenuti remoti;
- radio, testi, SponsorBlock ed equalizzatore con preset;
- statistiche di ascolto, riepiloghi e Time Machine;
- riproduzione in background e controlli dalla schermata di blocco.

### Musica locale

- importazione dei file audio indicizzati da Android MediaStore;
- scansione completa del dispositivo oppure selezione di una cartella specifica;
- ricerca e selezione multipla nei risultati della scansione;
- libreria persistente dei brani importati nel box Hive `localLibrary`;
- riproduzione diretta degli URI `content://`, senza copiare, spostare o eliminare i file originali;
- rimozione non distruttiva dei riferimenti dalla libreria;
- identità namespaced `local:` compatibili con player, Preferiti, playlist, coda e Android Auto;
- gestione fail-closed dei permessi `READ_MEDIA_AUDIO` e `READ_EXTERNAL_STORAGE`, con query MediaStore eseguite soltanto dopo il consenso esplicito.

### Playlist e Libreria

- playlist personalizzate contenenti insieme brani online, offline e locali;
- aggiunta dei nuovi brani in prima posizione e aggiornamento immediato della schermata aperta;
- evidenziazione visiva del brano attualmente in riproduzione nelle playlist e nei Preferiti;
- aggiunta simultanea di tutti i brani di una playlist ai Preferiti;
- copertine automatiche persistenti con immagini uniche e layout adattivo 2×2, diviso in due o singolo;
- supporto per cover personalizzate, che hanno sempre precedenza sul mosaico automatico;
- riordino drag-and-drop dei brani e delle playlist personali con salvataggio immediato in Hive;
- cartelle, playlist fissate e card Home dedicata all'ultima playlist personale riprodotta;
- condivisione delle playlist e dei Brani Preferiti come file CSV tramite lo Share Sheet Android;
- importazione di playlist da CSV Musify o Spotify con matching per ID, titolo e artista.

### Integrazione e interfaccia

- Android Auto con navigazione standard di Playlist, Preferiti e Musica locale, miniature dei brani e mosaici delle playlist;
- interfaccia Liquid Glass 2.0 con sfondo Aurora statico, superfici colorate dal tema, riflessi direzionali, profondità multilivello e blur selettivo;
- Material UI, colori dinamici, tema nero e interfaccia adattiva;
- localizzazione automatica basata sulla lingua del dispositivo;
- backup e ripristino dei dati trasferibili;
- controllo aggiornamenti GitHub configurabile, indicatore nelle Impostazioni e SnackBar non bloccante;
- compatibilità da Android 7 ad Android 16;
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

## Playlist personali e condivisione CSV

La card **Ultima Playlist** nella Home mostra sempre l'ultima playlist personale effettivamente avviata. L'ascolto successivo di un brano singolo, dei Preferiti, della musica locale o di una playlist suggerita non sostituisce questo riferimento. Titolo e copertina seguono in tempo reale le modifiche della playlist; se la playlist viene eliminata, la card torna allo stato vuoto.

Le viste delle playlist osservano direttamente i `ValueNotifier` della Libreria. Quando un brano viene aggiunto o rimosso, l'elenco aperto viene aggiornato immediatamente senza riavviare l'app. Il brano attualmente caricato nel player è evidenziato sia nella pagina della playlist sia nei **Brani Preferiti**; il confronto usa l'identità source-aware e riconosce anche gli ID locali `local:`.

### Copertine dinamiche

Se non è stata scelta una cover manuale, Musify salva nella playlist la selezione usata per la copertina automatica. Le immagini vengono deduplicate e il layout si adatta al contenuto:

| Copertine uniche disponibili | Layout |
| ---: | --- |
| 4 o più | mosaico 2×2 con quattro immagini |
| 2 o 3 | divisione in due riquadri |
| 1 | immagine singola a tutto riquadro |
| 0 | icona playlist predefinita |

La selezione resta stabile fra rebuild e riavvii. Una cover impostata dall'utente ha sempre la precedenza.

### Riordino persistente

- Dal menu di una playlist personale, **Ordina brani** apre la schermata drag-and-drop dedicata.
- Nella sezione **Libreria > Le mie Playlist**, il comando **Ordina playlist** consente di modificare nello stesso modo l'ordine delle playlist personali.
- Ogni spostamento viene salvato immediatamente nel box Hive `user`; ID, metadati, brani e cartelle non vengono ricreati né migrati.

Il comando **Condividi** nella pagina di una playlist e il pulsante dedicato nella raccolta **Brani Preferiti** creano un file CSV UTF-8 e aprono lo Share Sheet di sistema. I Preferiti condivisi possono essere importati su un altro dispositivo come una normale playlist. Il file contiene, nell'ordine salvato in Hive:

```text
Track Name, Artist Name, Track ID, Source, Album, Duration
```

Virgole, virgolette, testo Unicode e ritorni a capo vengono codificati secondo il formato CSV. Lo stesso file può essere scelto nella funzione **Importa playlist da Spotify** già presente nell'app: Musify usa prima gli ID esatti, risolve i riferimenti `local:` contro la libreria locale del dispositivo e usa titolo/artista come fallback. Il CSV contiene soltanto metadati e non incorpora né copia i file audio.

### Permessi Android

| Versione | API | Permesso richiesto |
| --- | ---: | --- |
| Android 7–12L | 24–32 | `READ_EXTERNAL_STORAGE` |
| Android 13–16 | 33–36 | `READ_MEDIA_AUDIO` |

Il permesso viene richiesto soltanto in seguito a un'azione esplicita dell'utente. La query MediaStore viene eseguita esclusivamente dopo la conferma del grant sia nel codice Dart sia nel bridge Kotlin.

## Interfaccia Liquid Glass

La release 11.5.1 introduce il sistema **Liquid Glass 2.0**, progettato per aumentare profondità e materialità mantenendo leggibilità e fluidità sia in modalità scura sia in modalità chiara:

- un campo Aurora statico a più gradienti offre al vetro colori reali da rifrangere senza animazioni o repaint continui;
- la tinta scelta dall'utente genera automaticamente varianti vivide, profonde e speculari che colorano il vetro invece di limitarsi a icone e pulsanti;
- AppBar principali, navigazione inferiore, mini-player, dialog di conferma e card Home usano un blur reale limitato e ritagliato;
- le superfici premium combinano riflessi radiali, bordo direzionale, ombra ambientale colorata e ombra di profondità esterna al clipping;
- le altre card, i menu, i bottom sheet e le righe delle Impostazioni simulano la rifrazione mediante trasparenze e gradienti, senza moltiplicare i filtri GPU;
- il master `assets/icons/musify_launcher_master_glass.png` alimenta icone launcher legacy, adaptive foreground, maschera monocromatica e asset interno in tutte le densità Android;
- nessun `BackdropFilter` viene creato nelle liste di brani, playlist o risultati di ricerca;
- colori e opacità si adattano a modalità chiara, scura e nero puro;
- il contrasto fra testo e superficie vitrea è verificato automaticamente rispetto alla soglia WCAG AA di 4,5:1.

Il sistema è concentrato nel componente riutilizzabile `lib/widgets/liquid_glass.dart`; non modifica modelli, persistenza, player, MediaStore o servizi Android Auto.

## Android Auto

Musify espone un `MediaBrowserService` attraverso `audio_service` e rende navigabili dal sistema dell'auto tre categorie principali:

- Playlist;
- Preferiti;
- Musica locale.

Le voci restituiscono elementi browsable o playable standard, supportano i comandi della sessione multimediale e la ricerca vocale. Ogni brano espone la propria copertina anche nelle liste di navigazione; le playlist senza cover manuale usano lo stesso mosaico adattivo 4/2/1 dell'app. La musica locale è mostrata soltanto quando il relativo permesso è già stato concesso sul telefono; Android Auto non tenta di aprire dialog di autorizzazione sul cruscotto.

### Attivare la build GitHub in Android Auto

La build APK scaricata da GitHub è installata manualmente, al di fuori di uno store riconosciuto da Android Auto. Per renderla disponibile sul cruscotto:

1. sul telefono aprire **Impostazioni**, cercare **Android Auto** e aprire le relative impostazioni;
2. scorrere fino a **Informazioni**, toccare **Versione** per mostrare *Versione e informazioni sulle autorizzazioni*, quindi toccare quella sezione 10 volte e confermare l'attivazione della modalità sviluppatore;
3. aprire il menu con i tre puntini in alto a destra e scegliere **Impostazioni sviluppatore**;
4. scorrere verso il basso e attivare **Origini sconosciute**;
5. disconnettere e riconnettere Android Auto. Musify sarà disponibile tra le app multimediali.

La stessa procedura è disponibile nell'app in **Impostazioni > Altri > Android Auto**. Abilitare le origini sconosciute esclusivamente per APK provenienti da repository attendibili. Per eventuali differenze fra versioni di Android Auto, consultare la [guida ufficiale ai test su un veicolo reale](https://developer.android.com/training/cars/testing#test-using-a-real-vehicle).

### Artwork nelle liste dell'auto

Il sottosistema artwork, invariato dalla release 11.4.4, usa un `ContentProvider` dedicato e URI locali opachi nel formato:

```text
content://com.danilo.musify.androidauto.artwork/art/<sha256>
```

Questa architettura segue le indicazioni Android per le app multimediali in auto: le immagini non vengono inserite come bitmap nelle transazioni Binder e gli URL remoti non vengono inviati direttamente al sistema di infotainment. Il provider restituisce JPEG quadrati da 512 px, applica il crop centrale, genera i mosaici lato nativo e conserva una cache persistente con limite di 96 MB.

Gli elementi delle liste sono trasferiti come descrizioni compatte: titolo, artista, album, ID namespaced e URI locale dell'artwork. URL originali, percorsi di riproduzione e metadati interni restano nel modello dell'app e vengono risolti soltanto quando l'utente avvia un brano. In questo modo anche le raccolte molto grandi restano sotto il limite Binder e conservano il caricamento progressivo delle miniature.

La strategia è ibrida:

- le sorgenti vengono registrate immediatamente, senza bloccare la costruzione dell'albero multimediale;
- la pre-cache parte all'inizializzazione e viene aggiornata quando cambiano playlist, Preferiti, Recenti, download o libreria locale;
- le prime 24 copertine di ogni raccolta e le prime 12 playlist vengono registrate con priorità, con un massimo di due download simultanei;
- un'immagine non ancora in cache viene risolta su richiesta dal provider;
- ogni sorgente è limitata a 8 MB, accetta soltanto HTTPS o URI locali autorizzati e viene ridimensionata prima di essere consegnata all'auto;
- le immagini duplicate vengono eliminate prima della composizione del mosaico.

Il provider non sostituisce né modifica `AudioService`: riproduzione, sessione multimediale, bridge MediaStore e ricerca conservano il percorso già collaudato. I riferimenti tecnici principali sono [Display media artwork](https://developer.android.com/training/cars/media/create-media-browser/media-artwork), [Content styles](https://developer.android.com/training/cars/media/create-media-browser/content-styles) e la [personalizzazione HMI di Android Automotive OS](https://source.android.com/docs/automotive/hmi/media/customization).

Il Manifest include il descrittore automotive `<uses name="media"/>`, il servizio media esportato, il receiver dei pulsanti multimediali e un'icona vettoriale monocromatica per l'interfaccia dell'auto.

## Aggiornamenti

Il controllo aggiornamenti consulta esclusivamente:

```text
https://api.github.com/repos/doctorloveapp/musify/releases/latest
```

Il comportamento è intenzionalmente non invasivo:

- nessun popup bloccante viene mostrato all'avvio;
- se **Controllo aggiornamenti automatici** è disabilitato non viene eseguita alcuna richiesta;
- il tag della release viene confrontato semanticamente con la versione installata;
- quando è disponibile una versione più recente compaiono un indicatore nelle Impostazioni e uno SnackBar non bloccante all'apertura;
- il pulsante dello SnackBar o il tap sull'indicatore apre la release nel repository ufficiale di questa distribuzione.

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

Build ARM64 offuscata per Samsung Galaxy S26, mantenendo il `versionCode` dichiarato nel `pubspec.yaml`:

```powershell
fvm flutter build apk --release --flavor github `
  --target-platform android-arm64 `
  --obfuscate `
  --split-debug-info=artifacts/symbols/11.5.1-build2010/android-arm64
```

L'APK viene prodotto in `build/app/outputs/flutter-apk/app-github-release.apk`. Non aggiungere `--split-per-abi`: Flutter applica agli APK split un offset numerico specifico per ABI. In questa release il `versionCode 2010` è mantenuto intenzionalmente uguale alla 11.5.0 per il ciclo di test indicato dal manutentore; una futura pubblicazione su store deve tornare a usare codici progressivi.

La directory indicata con `--split-debug-info` contiene la mappa necessaria a simbolizzare gli stack trace della build offuscata. Deve essere archiviata in modo sicuro insieme alla release e non pubblicata come allegato scaricabile. Esempio:

```bash
fvm flutter symbolize \
  -i crash_stacktrace.txt \
  -d artifacts/symbols/11.5.1-build2010/android-arm64/app.android-arm64.symbols
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

La release `11.5.1+2010` introduce Liquid Glass 2.0 esclusivamente nell'interfaccia mobile. La strategia usa blur reali soltanto su superfici piccole e fisse e rifrazione simulata altrove, evitando filtri nelle liste lunghe. Android Auto, il bridge MediaStore/Artwork, la riproduzione locale, Hive, la ricerca e il client WEB YouTube restano invariati rispetto alla release stabile precedente.

La release viene validata lato build con:

- analisi statica senza errori;
- 45 test automatici superati, inclusi URI artwork opachi, descrizioni Android Auto compatte, materializzazione locale, mosaico adattivo, ordine playlist persistente, identità del brano attivo, condivisione CSV dei Preferiti, rendering dark/light, vividezza della tinta, contrasto Liquid Glass e confinamento dei blur;
- smoke test reali del client YouTube superati per ricerca e paginazione di playlist con oltre 100 brani;
- build release ARM64 del flavor GitHub per Samsung Galaxy S26;
- offuscamento Dart verificato, simboli separati e sezioni DWARF rimosse dalla libreria ELF inserita nell'APK;
- verifica della firma APK;
- verifica del Manifest compilato, dei permessi e del servizio Android Auto;
- gate hardware 11.2 superato su Samsung Galaxy S26, One UI 8.5, Android 16;
- integrità del bridge Kotlin e continuità della firma verificate per l'aggiornamento in-place.

Artefatto verificato per il Samsung Galaxy S26:

```text
artifacts/Musify-11.5.1-build2010-samsung-s26-arm64-obfuscated.apk
SHA-256: 8CB663688D6B57F975A20F1B5C6D7D4E60A0B0734312FD6A3719F2F072432810
```

Il Manifest compilato riporta `com.danilo.musify`, `versionName 11.5.1` e `versionCode 2010`. La firma v2 usa lo stesso certificato Dan King delle release precedenti, consentendo l'aggiornamento in-place senza cancellare impostazioni, playlist, Preferiti o libreria locale. La disinstallazione, invece, elimina normalmente i dati applicativi locali e richiede quindi un backup preventivo.

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
| `lib/services/android_auto_artwork_service.dart` | registrazione URI, deduplicazione e pre-cache degli artwork per l'auto |
| `android/app/src/main/kotlin/com/danilo/musify/AndroidAutoArtworkProvider.kt` | caricamento, crop, mosaici e cache JPEG nativa per Android Auto/AAOS |
| `lib/screens/local_audio_import_page.dart` | accesso e riepilogo della libreria locale |
| `lib/screens/local_audio_scan_page.dart` | scansione full-screen, ricerca, selezione e importazione |
| `lib/screens/user_songs_page.dart` | elenco dei brani importati |
| `lib/services/playlists_manager.dart` | ordine playlist e metadati delle cover generate |
| `lib/utilities/playlist_cover.dart` | selezione persistente degli artwork del mosaico |
| `lib/screens/playlist_reorder_page.dart` | riordino drag-and-drop dei brani |
| `lib/screens/library_playlist_reorder_page.dart` | riordino drag-and-drop delle playlist personali |
| `lib/utilities/playlist_csv.dart` | codifica e parsing CSV condivisi fra export e import |
| `lib/services/playlist_sharing.dart` | file temporaneo e apertura dello Share Sheet |
| `lib/screens/import_spotify_playlist_page.dart` | import CSV Musify/Spotify e matching per ID/metadati |
| `lib/widgets/liquid_glass.dart` | mesh gradient, superfici vitree modulari e blur selettivo mobile |

Il player è basato su `audio_service` e `just_audio`. Un adapter converte i record locali nel contratto dati già utilizzato dall'app, evitando percorsi separati per coda, playlist e Preferiti.

## Compatibilità

| Configurazione | Valore |
| --- | --- |
| Package GitHub | `com.danilo.musify` |
| Package F-Droid | `com.danilo.musify.fdroid` |
| `minSdk` | 24 — Android 7 |
| `compileSdk` | 36 — Android 16 |
| `targetSdk` | 36 — Android 16 |
| Versione | `11.5.1+2010` |

## Download e segnalazioni

- [Scarica l'ultima release](https://github.com/doctorloveapp/musify/releases/latest)
- [Segnala un problema](https://github.com/doctorloveapp/musify/issues)
- [Proponi una modifica](https://github.com/doctorloveapp/musify/pulls)

Quando viene segnalato un problema relativo alla musica locale, indicare versione Android, produttore del dispositivo, stato del permesso audio e passaggi necessari a riprodurre l'errore. Non pubblicare path personali o file audio protetti.

## Manutenzione

**Dan King**<br>
GitHub: [@doctorloveapp](https://github.com/doctorloveapp)<br>
Email: [doctorloveapp@gmail.com](mailto:doctorloveapp@gmail.com)<br>
Repository: [doctorloveapp/musify](https://github.com/doctorloveapp/musify)

## Licenza

Musify è distribuito secondo i termini della [GNU General Public License v3.0](LICENSE). Il testo della licenza è conservato **senza modifiche** rispetto al progetto di partenza; la dichiarazione del fork si trova in [NOTICE.md](NOTICE.md), non nelle clausole legali. Le distribuzioni e le modifiche devono rispettare la GPL, rendere disponibile il codice sorgente corrispondente e conservare gli avvisi di copyright e licenza presenti nei file sorgente e nelle dipendenze.

## Esclusione di responsabilità

Musify non ospita né distribuisce contenuti audio protetti. I brani online, i file locali, i marchi e i relativi metadati appartengono ai rispettivi titolari. L'utente è responsabile dell'utilizzo dell'app nel rispetto delle leggi applicabili, del diritto d'autore e delle condizioni dei servizi utilizzati.

Il software viene fornito senza garanzie. Il manutentore non incoraggia la violazione del copyright e non assume responsabilità per usi impropri dell'applicazione o delle integrazioni di terze parti.
