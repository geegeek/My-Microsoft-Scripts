######################################################################################################
#                                                                                                    #
# Name:        ReplicaCheck.ps1                                                                      #
#                                                                                                    #
# Version:     1.1       21 Gennaio 2025                                                             #
#                                                                                                    #
# Description:                                                                                       #
#   Questo script esegue un controllo sugli errori di replica Active Directory tramite il comando    #
#   "repadmin /replsummary".                                                                         #
#                                                                                                    #
#   - Modalità Verbosa ($verboseMode = $true):                                                       #
#       1) Invia SEMPRE una mail, a prescindere dalla presenza di errori di replica.                 #
#       2) Nel corpo del messaggio, indica l'esito della sincronizzazione (se ci sono errori o meno).#
#       3) Allegato alla mail, in calce, viene sempre inserita una tabella HTML con il dump completo #
#          di "repadmin /replsummary".                                                               #
#                                                                                                    #
#   - Modalità Non Verbosa ($verboseMode = $false):                                                  #
#       1) Invia la mail SOLO se vengono rilevati errori di replica o server non contattati.         #
#       2) In caso di errori, indica le righe problematiche e, in calce, mostra una tabella HTML con #
#          l’output completo di "repadmin /replsummary".                                             #
#       3) Se non vengono rilevati errori, NON viene inviata alcuna mail.                            #
#                                                                                                    #
#   Lo script registra inoltre un file di log (transcript) contenente tutto l’output generato.       #
#                                                                                                    #
# Author:      geegeek                                                                    #
#                                                                                                    #
# Usage:                                                                                             #
#   - Eseguire manualmente o schedulare tramite Task Scheduler.                                      #
#   - Richiede privilegi adeguati (di solito su un DC) e che "repadmin" sia disponibile.             #
#                                                                                                    #
# Disclaimer:                                                                                        #
#   - Questo script è fornito "AS IS" senza alcun supporto.                                          #
#   - Si raccomanda di testarlo in un ambiente di laboratorio prima di utilizzarlo in produzione.    #
#                                                                                                    #
######################################################################################################


# FLAG PER MODALITÀ VERBOSA
# - $true => mail sempre inviata, con output dettagliato di repadmin
# - $false => mail inviata solo in caso di errori
[bool]$verboseMode = $false

# Percorso del file di log (Transcript)
$logFilePath = "C:\Scripts\ReplicaCheck\ReplicaCheck.log"

# Avvia la trascrizione (logging) in modalità append
Start-Transcript -Path $logFilePath -Append

try {
    Write-Output "=================================================="
    Write-Output "Inizio script di controllo replica DC - $(Get-Date)"
    Write-Output "=================================================="

    # Parametri SMTP ed Email - Rimuovi/Modifica con valori reali prima dell'uso
    $smtpServer = "SMTP_SERVER_IP_OR_HOSTNAME"
    $from       = "SENDER@DOMAIN"
    $to         = @("RECIPIENT1@DOMAIN","RECIPIENT2@DOMAIN")
    $subject    = "ALERT: Errori Replica DC"

    if ($verboseMode) {
        Write-Output "Modalità verbosa ABILITATA - la mail verrà inviata in ogni caso."
    }
    else {
        Write-Output "Modalità NON verbosa ABILITATA - la mail verrà inviata SOLO in caso di errori."
    }

    Write-Output "Esecuzione del comando repadmin /replsummary..."
    # Esegui repadmin, salvando l'output (in italiano) in un array di stringhe
    $replRaw = repadmin /replsummary
    Write-Output "Comando repadmin completato."

    # Convertiamo l'output in una tabella HTML
    $replObj = $replRaw | ForEach-Object {
        [PSCustomObject]@{ 
            "repadmin /replsummary" = $_ 
        }
    }
    $replTable = $replObj | ConvertTo-Html -Fragment -PreContent "<h3>Output completo di repadmin /replsummary</h3>" 

    # Cerchiamo errori di replica (fail > 0)
    Write-Output "Analisi errori di replica..."
    $errorLines = $replRaw | Where-Object {
        $_ -match "\d+\s*/\s*\d+"
    } | Where-Object {
        if ($_ -match "(\d+)\s*/\s*(\d+)") {
            [int]$matches[1] -gt 0
        }
    }

    # Cerchiamo server non contattati
    Write-Output "Analisi server non contattati..."
    $foundOpErrorSection = $false
    $opErrors = @()
    foreach ($line in $replRaw) {
        # Questa riga è un ESEMPIO di output in lingua italiana
        if ($line -like "*Si sono verificati i seguenti errori operativi tentando di recuperare le informazioni di replica:*") {
            $foundOpErrorSection = $true
            continue
        }
        if ($foundOpErrorSection -and $line -match "^\s*\d+\s*-\s*") {
            $opErrors += $line
        }
    }

    $hasErrors = ($errorLines.Count -gt 0 -or $opErrors.Count -gt 0)

    Write-Output "Composizione del corpo della mail in HTML..."
    # Corpo del messaggio in HTML
    $bodyHtml = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        h2, h3 { color: #333333; }
        table { border-collapse: collapse; font-size: 13px; margin-top: 10px; }
        th, td { border: 1px solid #888888; padding: 6px; text-align: left; }
        th { background-color: #f2f2f2; }
        .ok { color: green; }
        .warning { color: red; }
    </style>
</head>
<body>
<h2>Esito della Replica Active Directory</h2>
"@

    if ($hasErrors) {
        $bodyHtml += "<p class='warning'><strong>ATTENZIONE:</strong> Sono stati rilevati errori di replica.</p>"
        if ($errorLines.Count -gt 0) {
            $bodyHtml += "<p><strong>Errori di replica rilevati nelle seguenti linee:</strong><br/>"
            $bodyHtml += ($errorLines -join "<br/>") + "</p>"
        }
        if ($opErrors.Count -gt 0) {
            $bodyHtml += "<p><strong>Server non contattati:</strong><br/>"
            $bodyHtml += ($opErrors -join "<br/>") + "</p>"
        }
    }
    else {
        $bodyHtml += "<p class='ok'><strong>Nessun errore di replica rilevato.</strong></p>"
    }

    # Includiamo SEMPRE la tabella (modalità verbosa) o la includiamo SOLO se ci sono errori (non verbosa)
    # In realtà, per un debug completo, la includiamo in entrambi i casi in cui si invia la mail.
    $bodyHtml += $replTable

    $bodyHtml += @"
</body>
</html>
"@

    # Logica di invio email
    if ($verboseMode -or $hasErrors) {
        if ($verboseMode -and -not $hasErrors) {
            Write-Output "Modalità verbosa: nessun errore, ma si invia la mail comunque."
        }

        if ($hasErrors) {
            Write-Output "Si invia la mail perché ci sono errori di replica."
        }

        Send-MailMessage -SmtpServer $smtpServer `
                         -From $from `
                         -To $to `
                         -Subject $subject `
                         -Body $bodyHtml `
                         -BodyAsHtml
        Write-Output "Email inviata con successo."
    }
    else {
        Write-Output "Modalità non verbosa e nessun errore di replica. Non invio alcuna mail."
    }
}
catch {
    Write-Output "=================================================="
    Write-Output "Si è verificato un errore durante l'esecuzione dello script:"
    Write-Output $_
    Write-Output "=================================================="
}
finally {
    Write-Output "Fine script di controllo replica DC - $(Get-Date)"
    # Chiude la trascrizione (logging)
    Stop-Transcript
}
