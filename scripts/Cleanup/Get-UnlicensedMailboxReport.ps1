#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement, Microsoft.Graph.Users
<#
.SYNOPSIS
    Finds user mailboxes whose owner has no license with Exchange Online, or whose account is
    disabled (candidates for conversion to shared mailbox or removal).
.DESCRIPTION
    Requires Connect-ExchangeOnline and Connect-MgGraph (User.Read.All). Licensing is read from
    Graph assignedPlans: an enabled plan for service 'exchange' counts as licensed. Read-only.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-UnlicensedMailboxReport.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { throw 'Not connected to Graph. Run Connect-M365Admin -Service Graph, ExchangeOnline.' }
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox -Properties ExternalDirectoryObjectId, LitigationHoldEnabled, InPlaceHolds
$rows = foreach ($m in $mailboxes) {
    $u = Get-MgUser -UserId $m.ExternalDirectoryObjectId -Property AccountEnabled, AssignedPlans, UserPrincipalName -ErrorAction SilentlyContinue
    $hasExchange = [bool]($u.AssignedPlans | Where-Object { $_.Service -eq 'exchange' -and $_.CapabilityStatus -eq 'Enabled' })
    if (-not $hasExchange -or -not $u.AccountEnabled) {
        $stats = Get-EXOMailboxStatistics -Identity $m.ExternalDirectoryObjectId -Properties LastLogonTime -ErrorAction SilentlyContinue
        [pscustomobject]@{
            DisplayName        = $m.DisplayName
            UserPrincipalName  = $m.UserPrincipalName
            AccountEnabled     = $u.AccountEnabled
            ExchangeLicensed   = $hasExchange
            OnHold             = ($m.LitigationHoldEnabled -or @($m.InPlaceHolds).Count -gt 0)
            TotalItemSize      = "$($stats.TotalItemSize)"
            LastLogonTime      = $stats.LastLogonTime
            Recommendation     = if ($m.LitigationHoldEnabled) { 'Keep license (hold)' } else { 'Convert to shared or remove' }
        }
    }
}
$file = Join-Path $OutputFolder "UnlicensedMailboxes-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Candidates: $(@($rows).Count) of $(@($mailboxes).Count) user mailboxes -> $file" -InformationAction Continue
