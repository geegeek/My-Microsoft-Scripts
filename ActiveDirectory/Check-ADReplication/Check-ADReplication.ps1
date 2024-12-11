Param(
    [string]$SmtpServer = "smtp.example.com",
    [string]$From = "admin@example.com",
    [string]$To = "recipient@example.com",
    [string]$Subject = "ALERT: AD Replication Issues Detected"
)

# Esegue repadmin /replsummary e cattura l'output
$repl = repadmin /replsummary

# Cerca errori di replica (fail > 0)
$errorLines = $repl | Where-Object {
    $_ -match "\d+\s*/\s*\d+" 
} | Where-Object {
    if ($_ -match "(\d+)\s*/\s*(\d+)") {
        [int]$matches[1] -gt 0
    }
}

# Cerca eventuale sezione con server non contattati
$foundOpErrorSection = $false
$opErrors = @()
foreach ($line in $repl) {
    if ($line -like "*Experienced the following operational errors trying to retrieve replication information:*") {
        $foundOpErrorSection = $true
        continue
    }
    if ($foundOpErrorSection -and $line -match "^\s*\d+\s*-\s*") {
        $opErrors += $line
    }
}

# Se ci sono errori di replica o server non contattati, manda email
if ($errorLines.Count -gt 0 -or $opErrors.Count -gt 0) {
    $body = ""
    if ($errorLines.Count -gt 0) {
        $body += "Replication errors detected in the following lines:`n"
        $body += ($errorLines -join "`n") + "`n`n"
    }
    if ($opErrors.Count -gt 0) {
        $body += "The following servers could not be contacted:`n"
        $body += ($opErrors -join "`n") + "`n`n"
    }

    # Decommentare la linea seguente per includere l'output completo:
    # $body += "`nFull repadmin /replsummary output:`n" + ($repl -join "`n")

    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $body
}
