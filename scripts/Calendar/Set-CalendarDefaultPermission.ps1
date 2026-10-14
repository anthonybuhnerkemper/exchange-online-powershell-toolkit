#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Sets the Default (everyone in the organization) calendar permission on mailboxes, for example
    LimitedDetails for room mailboxes or AvailabilityOnly for executives.
.DESCRIPTION
    Requires Connect-ExchangeOnline (Exchange Administrator). Mailboxes already at the target
    level are skipped. Supports -WhatIf and -Confirm; writes a change log CSV.
.PARAMETER Identity
    Mailboxes to update.
.PARAMETER AccessRights
    AvailabilityOnly, LimitedDetails, Reviewer or None. Default LimitedDetails.
.PARAMETER OutputFolder
    Folder for the change log. Defaults to ./output.
.EXAMPLE
    ./Set-CalendarDefaultPermission.ps1 -Identity room-boardroom@contoso.com -AccessRights LimitedDetails -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string[]]$Identity,
    [ValidateSet('AvailabilityOnly', 'LimitedDetails', 'Reviewer', 'None')][string]$AccessRights = 'LimitedDetails',
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$log = foreach ($id in $Identity) {
    $cal = Get-EXOMailboxFolderStatistics -Identity $id -FolderScope Calendar | Where-Object FolderType -eq 'Calendar' | Select-Object -First 1
    $folderId = "${id}:\$($cal.Name)"
    $current = (Get-EXOMailboxFolderPermission -Identity $folderId -User Default).AccessRights -join ','
    $result = 'Skipped'
    if ($current -eq $AccessRights) { $result = 'AlreadySet' }
    elseif ($PSCmdlet.ShouldProcess($folderId, "Default permission $current -> $AccessRights")) {
        Set-MailboxFolderPermission -Identity $folderId -User Default -AccessRights $AccessRights | Out-Null
        $result = 'Changed'
    }
    [pscustomobject]@{ Mailbox = $id; Folder = $folderId; Previous = $current; Target = $AccessRights; Result = $result }
}
$file = Join-Path $OutputFolder "CalendarDefaultChanges-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$log | Export-Csv -Path $file -NoTypeInformation
Write-Information "Processed $(@($log).Count) mailbox(es) -> $file" -InformationAction Continue
