#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Converts user mailboxes to shared mailboxes (for example departed users) and optionally grants
    a manager Full Access.
.DESCRIPTION
    Requires Connect-ExchangeOnline (Exchange Administrator). Input is -Identity or a CSV with a
    UserPrincipalName column (such as Get-UnlicensedMailboxReport output). Shared mailboxes over
    50 GB, or with archive or hold, still need a license, so they are skipped unless -Force.
    Supports -WhatIf and -Confirm; writes a change log CSV.
.PARAMETER Identity
    One or more mailbox UPNs.
.PARAMETER CsvPath
    CSV with a UserPrincipalName column.
.PARAMETER GrantFullAccessTo
    Optional user to receive Full Access (AutoMapping off).
.PARAMETER Force
    Convert even when the mailbox is over 50 GB or on hold.
.PARAMETER OutputFolder
    Folder for the change log. Defaults to ./output.
.EXAMPLE
    ./Convert-MailboxToShared.ps1 -Identity former.user@contoso.com -GrantFullAccessTo manager@contoso.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Identity')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Identity')][string[]]$Identity,
    [Parameter(Mandatory, ParameterSetName = 'Csv')][string]$CsvPath,
    [string]$GrantFullAccessTo,
    [switch]$Force,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$targets = if ($PSCmdlet.ParameterSetName -eq 'Csv') { (Import-Csv $CsvPath).UserPrincipalName } else { $Identity }

$log = foreach ($upn in $targets) {
    $m = Get-EXOMailbox -Identity $upn -Properties LitigationHoldEnabled, ArchiveStatus
    $stats = Get-EXOMailboxStatistics -Identity $upn
    $sizeGB = [math]::Round(($stats.TotalItemSize.Value.ToBytes()) / 1GB, 2)
    $result = 'Skipped'
    if ($m.RecipientTypeDetails -eq 'SharedMailbox') { $result = 'AlreadyShared' }
    elseif (-not $Force -and ($sizeGB -gt 50 -or $m.LitigationHoldEnabled -or $m.ArchiveStatus -eq 'Active')) {
        $result = "NeedsLicense (size ${sizeGB} GB, hold $($m.LitigationHoldEnabled), archive $($m.ArchiveStatus)); use -Force"
    }
    elseif ($PSCmdlet.ShouldProcess($upn, 'Convert to shared mailbox')) {
        Set-Mailbox -Identity $upn -Type Shared
        $result = 'Converted'
        if ($GrantFullAccessTo -and $PSCmdlet.ShouldProcess($upn, "Grant FullAccess to $GrantFullAccessTo")) {
            Add-MailboxPermission -Identity $upn -User $GrantFullAccessTo -AccessRights FullAccess -AutoMapping $false | Out-Null
            $result += "; FullAccess -> $GrantFullAccessTo"
        }
    }
    [pscustomobject]@{ Mailbox = $upn; SizeGB = $sizeGB; Result = $result; Time = Get-Date }
}
$file = Join-Path $OutputFolder "ConvertToShared-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$log | Export-Csv -Path $file -NoTypeInformation
Write-Information "Processed $(@($log).Count) mailbox(es) -> $file. Remove licenses only after confirming conversion." -InformationAction Continue
