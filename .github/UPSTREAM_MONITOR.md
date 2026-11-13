# Sentinella delle dipendenze YouTube

Il workflow `check_upstream.yml` segnala modifiche upstream da revisionare. Non integra codice, non costruisce APK e non pubblica release.

## Cosa controlla

La configurazione è in `.github/upstream-monitor.json`. Sono monitorati tutti i sorgenti `lib/` dei due pacchetti YouTube vendorizzati e i punti applicativi di risoluzione degli stream: client, common services, proxy e audio handler. I nuovi file nelle directory monitorate vengono rilevati, come le modifiche, rimozioni e variazioni del modo Git. Modifiche esclusivamente fuori da questo perimetro non generano un avviso di aggiornamento.

Ogni esecuzione risolve `master` una volta e confronta i blob ID e i modi dei file fra due snapshot immutabili. Non legge né include nelle email il contenuto dei sorgenti. I blob ID Git sono identificatori di cambiamento, non certificazioni di integrità o sicurezza.

**La baseline è l'ultimo commit upstream revisionato, non l'insieme dei file locali del fork e non l'ultimo commit interamente importato.** Questo evita segnalazioni dovute alle nostre personalizzazioni intenzionali. Lo snapshot iniziale è `86fcaaf2664708c9fc8548f9b99f1ddd1e525257`, già analizzato il 13 novembre 2026; non tutte le sue modifiche sono state portate nel fork.

## Esecuzione e notifiche

- Restano il calendario esistente `0 9 */2 * *` (09:00 UTC nei giorni alterni indicati dal cron) e l'avvio manuale da GitHub Actions.
- Il job esegue prima test offline, poi il confronto GitHub API con permessi di sola lettura.
- In caso di differenze, invia una mail a `doctorloveapp@gmail.com` con commit, elenco dei file e link al confronto/cronologia.
- Non interpreta automaticamente una modifica come “critica” o come causa di un errore HTTP.
- Errori HTTP/API, timeout, JSON malformato e alberi Git troncati fanno fallire il controllo. Non sono interpretati come nuove versioni dei file; il workflow tenta una notifica distinta di controllo fallito.
- I secret SMTP restano `MAIL_USERNAME` e `MAIL_PASSWORD`, già usati dal workflow precedente. Il mittente usa l'account SMTP configurato, non un indirizzo esterno inventato.
- Nessuna deduplicazione persistente delle email è introdotta: una differenza non ancora revisionata viene segnalata nuovamente ai controlli successivi. La baseline non viene aggiornata automaticamente dopo una mail.

Per rendere operativo l'aggiornamento non serve una release dell'app: occorre includere i file della sentinella in un commit e portarli sul branch predefinito del fork. Da **Actions > Monitor Upstream Critical Dependencies > Run workflow** si potrà poi verificarne il funzionamento reale. L'invio SMTP e la schedulazione non sono dimostrati dai soli test locali.

## Come prendere in carico un avviso

1. Aprire il confronto tra i due commit riportati, limitando l'analisi ai file segnalati.
2. Distinguere parser/filtri, header/client, costanti e refactoring; verificare se esiste già una soluzione equivalente nel fork.
3. Decidere quali patch portare, rinviare o non adottare, con test e motivazione. Non effettuare un merge generale.
4. Dopo avere revisionato lo snapshot, aggiornare **manualmente** `baseline_commit` al suo SHA completo e `baseline_note` con data e motivo. Una revisione può concludersi anche senza importare codice.
5. Eseguire nuovamente test e sentinella. Non avanzare la baseline soltanto per silenziare una mail e non usare `master` o un tag mobile al posto dello SHA.

## Verifica locale, senza email

Python 3.12 o successivo; non sono richieste dipendenze esterne:

```text
python -B -m unittest discover -s scripts/tests -p "test_upstream_monitor.py" -v
python -B scripts/check_upstream.py
```

Su Windows con il launcher Python può essere usato `py -3` al posto di `python`.

Lo script genera `result.json` e `notification.txt` sotto `artifacts/upstream-monitor/`, già esclusa da Git. Nessuna email viene inviata dallo script locale: l'invio è un passo separato del workflow. Se presente, `GITHUB_TOKEN` viene usato solo per leggere le API e non viene stampato.

Documentazione tecnica: [Git trees API](https://docs.github.com/en/rest/git/trees#get-a-tree), [workflow GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [action di invio email](https://github.com/dawidd6/action-send-mail/tree/v3).
