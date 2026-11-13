# Promemoria operativo del fork

Prima di iniziare una richiesta che preveda modifiche all'app o una nuova APK:

1. Leggere `piano_fork.md`, se presente, in particolare il promemoria iniziale e le attività aperte.
2. Ricordare esplicitamente all'utente ciò che non è ancora stato completato, prima di procedere alla nuova build. Non aspettare la consegna per comunicare i rinvii.
3. Chiarire quali attività residue saranno incluse nella richiesta corrente e quali rimarranno aperte; non implementare nuovi interventi solo perché sono menzionati nel piano.
4. Aggiornare lo stato in modo veritiero, distinguendo codice, test locali, verifica GitHub Actions e test hardware. Non dichiarare completato l'intero piano se restano attività aperte.

`piano_fork.md`, `report_fork.md` e `piano_fasi.md` sono documenti privati ignorati: non aggiungerli al repository, non includerli in commit, release, email o artefatti pubblici. Non modificarne la privacy.

La sentinella segnala differenze upstream: non deve modificare automaticamente l'app o avanzare la baseline di revisione. Non generare nuove release o APK senza richiesta esplicita.
