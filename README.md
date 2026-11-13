<div align="center">
  <img src="assets/icons/musify_icon.png" width="128" alt="Icona Musify">

  # Musify

  **Streaming, playlist e musica locale in un unico player per Android.**

  [![Versione](https://img.shields.io/badge/versione-11.6.1-gold?style=flat-square)](https://github.com/doctorloveapp/musify/releases/latest)
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
- opzione **Salta brani non riproducibili**, persistente e disattivata per impostazione iniziale, con avanzamento automatico e avviso discreto in caso di errore;
- download e ascolto offline dei contenuti remoti;
- radio, testi statici e sincronizzati opzionali, SponsorBlock ed equalizzatore con preset;
- filtri stream YouTube opzionali DRM/OTF/DRC, disattivati di default, con suggerimento non bloccante in caso di stream non riproducibile;
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
- riordino drag-and-drop dei brani, dei Preferiti e delle playlist personali con salvataggio immediato in Hive;
- cartelle, playlist fissate e card Home dedicata all'ultima playlist personale riprodotta;
- condivisione delle playlist e dei Brani Preferiti come file CSV tramite lo Share Sheet Android;
- importazione di playlist da CSV Musify o Spotify con matching per ID, titolo e artista.

### Integrazione e interfaccia

- Android Auto con navigazione standard di Playlist, Preferiti e Musica locale, miniature dei brani e mosaici delle playlist;
- interfaccia Liquid Glass 2.0 con sfondo Aurora statico, superfici colorate dal tema, riflessi direzionali, profondità multilivello e blur selettivo;
- player a schermo intero in stile Liquid Glass, con copertina incorniciata, controlli circolari, titolo su due righe e barra delle azioni satinata;
- Material UI, colori dinamici, tema nero e interfaccia adattiva;
- palette di 52 colori con rosso rubino, viola, lilla, grigi e blu profondi;
- localizzazione automatica basata sulla lingua del dispositivo;
- backup e ripristino dei dati trasferibili;
- controllo aggiornamenti GitHub configurabile, indicatore nelle Impostazioni e SnackBar non bloccante;
- compatibilità da Android 7 ad Android 16;
- nessuna pubblicità e nessun abbonamento.

## Resilienza del player

In **Impostazioni > Preferenze**, **Salta brani non riproducibili** abilita il passaggio al prossimo elemento della coda quando un contenuto non può essere caricato o la riproduzione fallisce. La scelta viene salvata in Hive e vale per playlist, Preferiti e coda manuale. Quando avviene un salto, una SnackBar informa l'utente senza interrompere la navigazione.

Il player mantiene il tentativo di rinnovo dell'URL prima di rinunciare a uno stream. Gli errori duplicati non producono salti multipli; a fine coda o dopo un giro di soli brani non disponibili con Repeat All, l'ascolto si ferma. Con l'opzione disattivata il player resta sul brano fallito. Il cambio manuale di brano annulla il recupero dell'operazione precedente.

## Testi sincronizzati e fallback statico

Da `11.6.1+2014`, **Impostazioni > Testi sincronizzati** è **attivo di default quando la preferenza non esiste**. Una scelta già salvata, incluso OFF, viene rispettata durante l'aggiornamento. Quando abilitato, il retro della copertina segue la riga del testo, consente di toccarla per eseguire il seek e offre una regolazione temporale di 0,5 secondi. Lo scorrimento manuale sospende temporaneamente l'inseguimento automatico. Il tema scelto dall'utente e il player Liquid Glass restano invariati.

Il percorso sincronizzato usa LRCLIB e ripiega sulle fonti testuali statiche quando non trova timestamp utilizzabili. Disabilitando il toggle resta il percorso statico preesistente. Se tutte le fonti sono irraggiungibili o non hanno il brano, viene mostrato lo stato di testo non disponibile: la riproduzione non dipende dalla disponibilità dei testi.

Il recupero parte solo aprendo il pannello dei testi, non scorrendo le playlist. Le richieste identiche sono condivise; la cache è limitata a 50 risultati in RAM, con validità di 6 ore per i successi e 5 minuti per le assenze, e il nuovo recupero ha un budget complessivo di 15 secondi. Non viene creata una libreria di testi offline. I risultati dipendono dai metadati e dalla disponibilità dei provider: versioni live, remix o file locali con informazioni incomplete possono non avere sincronizzazione.

Modelli, parser LRC e parte del recupero sono adattati dal [progetto originale](https://github.com/gokadzev/Musify/commit/247476cb66af), mantenendone attribuzioni e licenza. La fonte dei testi è indicata nella vista.

## Filtri avanzati stream YouTube

In **Impostazioni > Avanzate > Abilita filtri avanzati stream YouTube** è possibile attivare l'esclusione dei formati DRM, OTF e DRC prevista dalla patch upstream. Il toggle è **disattivato di default**, persiste in Hive e può essere disabilitato in caso di incompatibilità. Agisce sulle nuove risoluzioni: non riavvia il brano in corso. Il percorso avanzato usa una cache URL/header separata da quella standard, senza cancellare i record precedenti.

In caso di errore terminale di uno stream online, incluso un 403, un avviso non bloccante suggerisce di provare il filtro se è spento. Non viene attivato automaticamente: il suggerimento è limitato a uno ogni due minuti, fino a tre per sessione, e non riguarda il semplice fallimento del prefetch dei brani successivi. I filtri possono aiutare la compatibilità, ma non eliminano ogni restrizione e non garantiscono di evitare la classificazione del traffico come automatizzato.

La stessa opzione abilita un fallback finito visionOS → Android e associa agli URL gli header del client che li ha generati, mantenendoli coerenti per riproduzione online, download e validazione cache. Cookie, autorizzazioni e host estranei sono esclusi. I tentativi hanno un budget limitato e si interrompono su timeout, 429 o restrizioni esplicite. OFF conserva il client e i retry standard.

Sono aggiornati anche i parser dei dati iniziali JSON, le date relative e i layout playlist, con pagination WEB_REMIX oltre 200 brani e fallback web per uploads/mix. Le patch provengono dallo [snapshot upstream revisionato](https://github.com/gokadzev/Musify/tree/86fcaaf2664708c9fc8548f9b99f1ddd1e525257), non da un merge integrale.

I proxy restano esclusivamente opt-in. Per i proxy abilitati è mantenuta la verifica TLS e vengono validati gli endpoint pubblici; la verifica usa connessioni separate dal client attivo. Nessuna attivazione implicita del proxy.

## Manutenzione automatica della cache

Una volta per avvio, dopo il primo frame, Musify elimina dal solo box generico `cache` le voci con timestamp invalido o più vecchie di 30 giorni. Le operazioni sono coordinate per preservare scritture recenti; la manutenzione cede periodicamente l'event loop e gli errori non bloccano l'avvio. Non vengono cancellati file, artwork Android Auto, download, impostazioni, playlist, Preferiti o libreria locale. I normali TTL restano invariati.

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
- Lo stesso comando è disponibile anche nel dialog aperto dalla **matita** della playlist, come accesso aggiuntivo.
- Nei **Brani Preferiti**, la **matita** accanto a Condividi apre il riordino dei brani. Riproduci e Condividi restano accessibili sulla stessa riga.
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

Il sistema è concentrato nel componente riutilizzabile `lib/widgets/liquid_glass.dart`; non modifica modelli, persistenza, motore audio, MediaStore o servizi Android Auto.

### Player a schermo intero

Dalla `11.5.4+2012`, il player riprende il linguaggio visivo della Home con controlli circolari in vetro, riflessi direzionali, ombre diffuse e una copertina incorniciata. Play/Pausa è il comando principale; Shuffle, Precedente, Successivo e Repeat restano immediatamente accessibili. Il colore scelto nelle Impostazioni si riflette nelle superfici, nei bordi e nella barra di avanzamento, sia in modalità chiara sia scura.

Il titolo dispone di due righe e il nome dell'artista conserva il collegamento alla sua pagina. Download, timer, aggiunta a playlist, coda, testi e Preferiti rimangono nella barra inferiore satinata. La copertina continua a ruotare per mostrare i testi; radio e brani locali mantengono le azioni pertinenti alla loro origine.

Il layout usa lo spazio realmente disponibile e supporta smartphone compatti, landscape, tablet e testo ingrandito. I comandi principali mantengono un'area di tocco di almeno 48 punti logici. Per limitare il lavoro della GPU, i pulsanti e la cornice simulano la rifrazione con gradienti statici: l'unico blur aggiunto dal player è circoscritto alla barra inferiore. La progressione del brano aggiorna un sottoalbero isolato, senza ridisegnare copertina e controlli.

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
  --split-debug-info=artifacts/symbols/11.6.1-build2014/android-arm64
```

L'APK viene prodotto in `build/app/outputs/flutter-apk/app-github-release.apk`. Le dipendenze native possono includere librerie accessorie di altre ABI anche con `--target-platform android-arm64`: l'artefatto finale in `artifacts/` viene ripacchettizzato per la sola `arm64-v8a`, riallineato e rifirmato con il certificato originale. Non modificare lo ZIP dopo la firma. Non aggiungere `--split-per-abi`: Flutter applica agli APK split un offset numerico specifico per ABI. La release `11.6.1+2014` incrementa il `versionCode` a `2014`, rispetto al `2013` della release precedente.

La directory indicata con `--split-debug-info` contiene la mappa necessaria a simbolizzare gli stack trace della build offuscata. Deve essere archiviata in modo sicuro insieme alla release e non pubblicata come allegato scaricabile. Esempio:

```bash
fvm flutter symbolize \
  -i crash_stacktrace.txt \
  -d artifacts/symbols/11.6.1-build2014/android-arm64/app.android-arm64.symbols
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

La release `11.6.1+2014` completa parser/pagination, risoluzione stream opzionale e cleanup automatico, con testi sincronizzati ON di default se non esiste una preferenza salvata. Il percorso Dart online propaga gli header quando il modo avanzato è attivo; sorgenti locali e logica skip/coda restano invariati. Nessuna modifica a Kotlin, MediaStore, browsing/artwork Android Auto o estetica Liquid Glass.

Verifiche della consegna:

- baseline prima delle modifiche: **105 test Flutter superati**;
- suite finale: **178 test Flutter superati**, inclusi parser vecchi/nuovi, pagination di 300 brani, fallback, header/redirect, 401/403/429, deadline, cache concorrente, preferenze, UI e resilienza;
- **18 test Python** della sentinella superati;
- `fvm flutter analyze --no-pub`: nessun problema;
- APK esclusivamente ARM64 offuscata, simboli separati, allineamento 16 KiB, Manifest e firma originale v2/v3 verificati;
- nessuna nuova dipendenza, modifica nativa Android o migrazione dei box.

È richiesto il **gate hardware sul Samsung S26**: aggiornamento sopra l'installazione esistente, testi, stream con filtri OFF/ON, download, playlist ibride e smoke Android Auto. Non è stato eseguito un nuovo test live del catalogo YouTube; test automatici e diff invariato non sostituiscono collaudo e misure di fluidità sul dispositivo.

Artefatto verificato:

```text
artifacts/Musify-11.6.1-build2014-samsung-s26-arm64-obfuscated.apk
SHA-256: D408BAB0CDBCECD31AB0B8E8C4B6E0D462AAD54BAFC3214AC96F63F98978DF20
```

Il Manifest riporta `com.danilo.musify`, `versionName 11.6.1` e `versionCode 2014`. La firma usa lo stesso certificato Dan King delle release precedenti. Non disinstallare l'app o cancellarne i dati: non sono introdotte migrazioni di impostazioni, playlist, Preferiti o libreria locale.

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
| Versione | `11.6.1+2014` |

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
