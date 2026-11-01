# v1.07-A2 — Preparazione contestuale degli appuntamenti

Stato: implementazione source candidate, non ancora certificata su dispositivo.

- CAP-0003. Da menu azioni di appuntamenti privati (non attività, non calendari esterni, non eventi condivisi), `Prepara l'appuntamento`.
- Un editor modale usa `AgendaItem.note`: campo nota libero e righe checklist `☐` / `☑` in coda al testo. La forma è leggibile anche dall'editor evento preesistente. Nessuna nuova tabella, storage, entità, scheduler, trasporto sync o costo cloud.
- Aggiungere, spuntare/rimuovere elementi; una nuova riga ancora nel campo di inserimento viene acquisita premendo Salva. Il pulsante Annulla non effettua write; la conferma usa `AgendaStore.upsert(current.copyWith(note: nextNote))` con snapshot corrente.
- La rilettura della sorgente previene la sovrascrittura delle note concorrenti; in conflitto o perdita sorgente l'editor rimane aperto con la bozza e messaggio d'errore. In cambio account l'editor deve chiudere senza scrivere nell'altro account.
- Archiviazione, Trash, backup/restore e sync usano la rappresentazione esistente dell'appuntamento. Nessun reminder nuovo: gli eventuali reminder dell'evento rimangono sotto il proprietario originale.
- Cinque lingue UI già supportate: EN, IT, ES, FR, PT. UI leggera, Material semantico, compatibile con mobile e Web.
- Test: codec nota/checklist, conservazione testo libero, roundtrip, no-op, modifica remota, fail-next-batch con retry persistito, isolamento account, rimozione evento e restore da Trash.
- Questi test CI sono sorgente, non test fisici. L'APK firmato +115 non contiene A1 né A2; il prossimo APK richiede un `versionCode > 115`, firma stabile e verifica specifica.

Non gestire checklist condivise o riferimenti ad altre persone senza una distinta approvazione di permessi e privacy.
