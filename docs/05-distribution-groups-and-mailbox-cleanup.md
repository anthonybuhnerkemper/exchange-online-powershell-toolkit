# 05 - Distribution groups and license-based mailbox cleanup

## 1. Distribution group report
```powershell
./scripts/Groups/Get-DistributionGroupReport.ps1 -IncludeMembers
```
Look for `Empty`, `NoOwner`, and `AcceptsExternalSenders = TRUE` groups. Consider converting suitable groups to Microsoft 365 groups.

## 2. Find unlicensed or disabled user mailboxes
```powershell
Connect-M365Admin -Service Graph, ExchangeOnline -Interactive
./scripts/Cleanup/Get-UnlicensedMailboxReport.ps1
```
Unlicensed user mailboxes are deleted 30 days after the license is removed, so act on this list.

## 3. Convert departed users to shared mailboxes
```powershell
./scripts/Cleanup/Convert-MailboxToShared.ps1 -CsvPath ./output/UnlicensedMailboxes-<stamp>.csv -WhatIf
./scripts/Cleanup/Convert-MailboxToShared.ps1 -Identity former.user@contoso.com -GrantFullAccessTo manager@contoso.com
```
Shared mailboxes over 50 GB, or with an archive or a hold, still need an Exchange Online Plan 2 license; the script skips those unless `-Force`.
