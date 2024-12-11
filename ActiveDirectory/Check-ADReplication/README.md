# Check Active Directory Replication

This script checks for replication issues across Domain Controllers using `repadmin /replsummary`.

## Features
- Detects replication errors (fail > 0).
- Identifies unreachable servers.
- Sends email notifications in case of issues.

See the main `Check-ADReplication.ps1` script for details.
