#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Audits Full Access, Send As and Send on Behalf permissions on shared (or all) mailboxes.
.DESCRIPTION
    Requires Connect-ExchangeOnline. Inherited and system (NT AUTHORITY\SELF, S-1-5-*) entries are
    excluded. One CSV row per mailbox, trustee and right. Read-only.
.PARAMETER AllMailboxes
    Audit user mailboxes too, not only shared mailboxes.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SharedMailboxPermissionAudit.ps1
#>
[CmdletBinding()]
param(
    [switch]$AllMailboxes,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$types = if ($AllMailboxes) { 'UserMailbox', 'SharedMailbox' } else { 'SharedMailbox' }
$mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $types -Properties GrantSendOnBehalfTo
$rows = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($m in $mailboxes) {
    $i++
    Write-Progress -Activity 'Mailbox permissions' -Status $m.PrimarySmtpAddress -PercentComplete (100 * $i / @($mailboxes).Count)
    Get-EXOMailboxPermission -Identity $m.ExternalDirectoryObjectId |
        Where-Object { -not $_.IsInherited -and $_.User -notmatch '^(NT AUTHORITY|S-1-5-)' } |
        ForEach-Object { $rows.Add([pscustomobject]@{ Mailbox = $m.PrimarySmtpAddress; Type = $m.RecipientTypeDetails; Trustee = $_.User; Right = ($_.AccessRights -join ',') }) }
    Get-EXORecipientPermission -Identity $m.ExternalDirectoryObjectId |
        Where-Object { $_.Trustee -notmatch '^(NT AUTHORITY|S-1-5-)' } |
        ForEach-Object { $rows.Add([pscustomobject]@{ Mailbox = $m.PrimarySmtpAddress; Type = $m.RecipientTypeDetails; Trustee = $_.Trustee; Right = 'SendAs' }) }
    foreach ($delegate in $m.GrantSendOnBehalfTo) {
        $rows.Add([pscustomobject]@{ Mailbox = $m.PrimarySmtpAddress; Type = $m.RecipientTypeDetails; Trustee = $delegate; Right = 'SendOnBehalf' })
    }
}
Write-Progress -Activity 'Mailbox permissions' -Completed
$file = Join-Path $OutputFolder "MailboxPermissions-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Mailboxes: $(@($mailboxes).Count)  Permission entries: $($rows.Count) -> $file" -InformationAction Continue
