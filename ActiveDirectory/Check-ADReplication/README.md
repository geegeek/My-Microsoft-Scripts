# Active Directory Replication Check

This PowerShell script runs the command ```repadmin /replsummary``` to analyze the replication status of Active Directory Domain Controllers.  
If there are replication errors (fail > 0) or unreachable servers, it sends an email notification.  
If no issues are detected, no email is sent.

## How it Works

1. The script executes ```repadmin /replsummary```.
2. It analyzes the output looking for:
   - **Replication errors:** Occur when the ```fails/total``` column shows a number of failures (```fails```) greater than 0.
   - **Unreachable servers:** Listed in the final section of the ```repadmin /replsummary``` output after the line:
     ```  
     Experienced the following operational errors trying to retrieve replication information:  
     ```

3. If replication errors or unreachable servers are found, the script sends an alert email containing the offending lines.  
   Otherwise, it does not send any email, keeping the notification system "quiet" when everything is working properly.

4. If you want to include the entire ```repadmin /replsummary``` output in the email for further diagnosis, you can uncomment the indicated line in the script.

## Requirements

- Windows Server with ```repadmin``` available (typically on a Domain Controller or with RSAT installed).
- PowerShell (5.1 or later).
- Access to an SMTP server for sending emails.

## Installation

1. Clone or download this repository.
2. Open ```Check-ADReplication.ps1``` and modify the default parameters (```$SmtpServer``` , ```$From``` , ```$To```) according to your needs, or use command-line parameters.

## Usage

Run the script with PowerShell:
```powershell
.\Check-ADReplication.ps1 -SmtpServer "smtp.example.com" -From "admin@example.com" -To "recipient@example.com"
```

You can schedule the execution of the script with Task Scheduler for continuous monitoring (e.g., every 30 minutes).

### Example of Output and Behavior

**Case 1: No Errors and No Unreachable Servers**

Extracted simplified ```repadmin /replsummary``` output:

```  
Source DSA          largest delta    fails/total %%   error  
DC1                  00m:05s         0 /   6    0   
DC2                  00m:10s         0 /   6    0   
  
(No operational errors)  
```

In this case:  
- No DC has ```fails``` > 0.  
- No unreachable servers.  
- Result: The script does not send an email.

**Case 2: Replication Errors (fail > 0)**

Extracted simplified ```repadmin /replsummary``` output:

```  
Source DSA          largest delta    fails/total %%   error  
DC1                  00m:05s         2 /   6    33   
DC2                  00m:10s         0 /   6     0  
  
(No operational errors)  
```

In this case:  
- DC1 has 2 failures (2 / 6).  
- No unreachable servers.  
- Result: The script sends an email highlighting DC1's errors.

**Case 3: No Failures but Unreachable Servers**

Extracted simplified ```repadmin /replsummary``` output:

```  
Source DSA          largest delta    fails/total %%   error  
DC1                  00m:05s         0 /   6     0  
DC2                  00m:10s         0 /   6     0  
  
Experienced the following operational errors trying to retrieve replication information:  
          58 - DC3.example.local  
          58 - DC4.example.local  
```

In this case:  
- All ```fails``` are 0.  
- There are unreachable servers (DC3 and DC4).  
- Result: The script sends an email with the list of unreachable servers.

**Case 4: Both Replication Errors and Unreachable Servers**

Extracted simplified output:

```  
Source DSA          largest delta    fails/total %%   error  
DC1                  00m:05s         1 /   6    16  
DC2                  00m:10s         0 /   6     0  
  
Experienced the following operational errors trying to retrieve replication information:  
          58 - DC3.example.local  
```

In this case:  
- DC1 has replication errors.  
- DC3 is unreachable.  
- Result: The script sends an email including both the DC1 errors and the unreachable server (DC3).

**Notes**

- To include the full ```repadmin /replsummary``` output in the email, uncomment the indicated line in the script source code.  
- The script does not modify any settings; it only performs a check and notifies by email in case of issues.  
- Test the script in a test environment before using it in production.  
