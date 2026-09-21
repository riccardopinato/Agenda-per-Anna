# Supabase backend — Agenda per Anna

Questa cartella contiene lo schema cloud della v0.15 e la base dati già predisposta per la v0.16 "Spazio condiviso".

## Ordine di applicazione

1. Creare un progetto Supabase dedicato ad Agenda per Anna.
2. Applicare `migrations/001_cloud_sync.sql`.
3. In Auth abilitare Email/Password.
4. Usare nell'app solo:
   - Project URL
   - Publishable key
5. Non inserire mai la service-role key nel client Flutter.

## Modello dati

`agenda_records` contiene sia record privati sia, dalla v0.16, record condivisi.

- `visibility = private` → `space_id IS NULL`, accesso esclusivo del proprietario.
- `visibility = shared` → `space_id` valorizzato, accesso consentito solo ai membri dello spazio.
- `record_key` è l'identificatore globale usato per gli upsert incrementali.
- `deleted_at` implementa tombstone per sincronizzare correttamente le eliminazioni.
- `client_updated_at` consente la risoluzione deterministica dei conflitti offline.

## Sicurezza

RLS è obbligatoria su tutte le tabelle cloud. La funzione `is_space_member()` centralizza il controllo membership senza creare ricorsione nelle policy di `space_members`.

Gli inviti di `space_invites` sono volutamente non accessibili direttamente dal client nella v0.15. La v0.16 userà RPC/Edge Function dedicate per:
- generare un codice temporaneo;
- validare il codice;
- aggiungere il secondo account allo spazio;
- revocare/rigenerare gli inviti.

## Configurazione build

Flutter legge:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

tramite `--dart-define`.

La build resta completamente funzionante offline se le variabili non sono presenti.
