# ReplicaCheck.ps1

Script PowerShell per il controllo giornaliero degli errori di replica **Active Directory** mediante `repadmin /replsummary`.

---

## Caratteristiche

- **Verifica** la presenza di eventuali errori di replica (fail > 0) o server non contattati.  
- **Modalità Verbosa** (`$verboseMode = $true`):
  - Invia **sempre** un’email con:
    - Esito della sincronizzazione (se ci sono errori oppure no).
    - Tabella HTML contenente l’intero output di `repadmin /replsummary`.
- **Modalità Non Verbosa** (`$verboseMode = $false`):
  - Invia **solo** in caso di errori:
    - Dettagli degli errori riscontrati.
    - Output di `repadmin /replsummary` in forma tabellare.
  - Non manda email se non sono presenti errori.

---

## Requisiti

- **PowerShell** 5.1 o successivo (o PowerShell Core/7 se installato su Windows).
- **repadmin** disponibile (di solito presente su un Domain Controller).
- **Permessi** adeguati per eseguire `repadmin`.
- **SMTP** server configurato per `Send-MailMessage` (o usare un modulo alternativo come `Send-MailKitMessage` se necessario).
- **Esecuzione** abilitata degli script PowerShell (se richiesto da `ExecutionPolicy`):
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
