# ReplicaCheck.ps1

Script PowerShell per il controllo giornaliero degli errori di replica
**Active Directory** mediante il comando `repadmin /replsummary`.

## Caratteristiche

-   **Verifica** la presenza di eventuali errori di replica (`fail > 0`)
    o server non contattati.
-   **Modalità Verbosa** (`$verboseMode = $true`):\
    \* Invia **sempre** un'email con:\
    \* Esito della sincronizzazione (se ci sono errori oppure no).\
    \* Tabella HTML contenente l'intero output di
    `repadmin /replsummary`.
-   **Modalità Non Verbosa** (`$verboseMode = $false`):\
    \* Invia **solo** in caso di errori:\
    \* Dettagli degli errori riscontrati.\
    \* Output di `repadmin /replsummary` in forma tabellare.\
    \* Non manda email se non sono presenti errori.

## Requisiti

-   **PowerShell** 5.1 o successivo.
-   **repadmin** disponibile (di solito presente su un Domain
    Controller).
-   **Permessi** adeguati per eseguire `repadmin`.
-   **SMTP** server configurato per `Send-MailMessage`.
-   **Esecuzione script** abilitata:
        Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

## Configurazione e Organizzazione delle Cartelle

Per una struttura pulita ed efficace, si consiglia la seguente gerarchia
di cartelle:

    C:\Scripts
      └─ReplicaCheck
         ├─ ReplicaCheck.ps1
         ├─ ReplicaCheck.log   (verrà generato automaticamente se non esiste)
         └─ README.md

1.  Clona o copia lo script `ReplicaCheck.ps1` e il file `README.md`
    nella cartella `C:\Scripts\ReplicaCheck`.
2.  Apri `ReplicaCheck.ps1` e personalizza i valori:\
    \* `$smtpServer = "SMTP_SERVER_IP_OR_HOSTNAME"`\
    \* `$from = "SENDER`DOMAIN"@\
    \* `$to = `("RECIPIENT1@DOMAIN","RECIPIENT2@DOMAIN")@\
    \* `$verboseMode = $false` (o `$true`, se preferisci).

## Pianificazione con Windows Task Scheduler

Per eseguire automaticamente lo script (ad esempio, una volta al
giorno), utilizza il **Task Scheduler** di Windows:

1.  **Creare un utente dedicato** (es. `svc_ReplicaCheck`) con privilegi
    minimi ma sufficienti per:\
    \* Eseguire script PowerShell.\
    \* Inviare email tramite SMTP.\
    \* Eseguire `repadmin` (di solito su un Domain Controller o una
    macchina con RSAT/ADDS Tools).\
    \* **Nota**: è consigliabile usare una password robusta e politiche
    di sicurezza adeguate.
2.  Apri il Task Scheduler (`taskschd.msc`).
3.  Crea un nuovo task:\
    \* **Nome**: `ReplicaCheck` (o un nome significativo).\
    \* **Descrizione**: Controllo giornaliero della replica AD.\
    \* **User account**: `svc_ReplicaCheck`.\
    \* Seleziona **Run whether user is logged on or not**.
4.  Configura i parametri:\
    \* **Trigger**: Avvio giornaliero (es. ogni giorno alle 02:00 AM).\
    \* **Action**: Avvia un programma:\
    \* **Program/script**: `powershell.exe`\
    \* **Arguments**:
        -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\ReplicaCheck\ReplicaCheck.ps1"

    \
    \* **Conditions**: Disabilita "Start the task only if the computer
    is on AC power" (se necessario).\
    \* **Settings**:\
    \* Spunta **Allow task to be run on demand**.\
    \* Abilita **Run task as soon as possible after a scheduled start is
    missed** (opzionale).
5.  Conferma e salva il task, immettendo la password dell'utente
    dedicato.

Una volta completata la configurazione, il Task Scheduler eseguirà lo
script `ReplicaCheck.ps1` regolarmente. Se hai impostato
`$verboseMode = $true`, riceverai SEMPRE una mail; se
`$verboseMode = $false`, solo in caso di errori.

## Esempio di output `repadmin /replsummary`

In un **ambiente AD in lingua italiana**, `repadmin /replsummary`
potrebbe produrre:

    Inizio summarizzazione replica in corso per tutti i server...
    21/01/2025 09:15:32
    Si sono verificati i seguenti errori operativi tentando di recuperare le informazioni di replica:
        8453 - "Access is denied."

    REPLICAZIONE PER SUMMARY:

    Source DSA          largest delta    fails/total %% error
    DCTEST1               0:01:45         0 /   10    0
    DCTEST2               0:02:12         1 /   10   10 (errore)

    Dest DSA             largest delta    fails/total  %% error
    DCTEST1               0:01:45         0 /   10    0
    DCTEST2               0:02:10         0 /   10    0

Lo script cercherà le righe con `fails/total` \> 0 e la frase:\
**"Si sono verificati i seguenti errori operativi tentando di recuperare
le informazioni di replica:"**\
per individuare **server non contattati** e **errori di replica**.

## Note

-   **Lingua Italiana**: Assicurati che l'output di `repadmin`
    corrisponda al pattern usato dallo script.
-   **Log di Trascrizione**: Tutto l'output dello script è registrato
    nel file `ReplicaCheck.log` nella stessa cartella dello script.
-   **Sicurezza**: Usa un account **dedicato** e con privilegi minimi
    quando configuri il task.
-   **Personalizzazione**: Modifica i parametri SMTP, email e la logica
    di parsing se necessario.

## Contribuire

1.  **Fork** e **clona** il repository.
2.  Crea un branch con la tua feature o fix.
3.  **Commit** i cambiamenti e invia una Pull Request.

## Licenza

Questo script è fornito "as is" senza garanzia o supporto. Usalo a tuo
rischio e pericolo.
