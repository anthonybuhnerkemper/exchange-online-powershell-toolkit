#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Exports every mailbox with type, size, item count, archive and litigation hold state to CSV.
.DESCRIPTION
    Requires Connect-ExchangeOnline (View-Only Recipients or Exchange Administrator). Uses the REST
    based Get-EXOMailbox and Get-EXOMailboxStatistics cmdlets. -SkipStatistics makes it much
    faster on large tenants. Read-only.
.PARAMETER RecipientTypeDetails
    Mailbox types to include. Default UserMailbox, SharedMailbox, RoomMailbox, EquipmentMailbox.
.PARAMETER SkipStatistics
    Do not query size and item count.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-EXOMailboxInventory.ps1
.EXAMPLE
    ./Get-EXOMailboxInventory.ps1 -RecipientTypeDetails SharedMailbox -SkipStatistics
#>
[CmdletBinding()]
param(
    [ValidateSet('UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox')]
    [string[]]$RecipientTypeDetails = @('UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox'),
    [switch]$SkipStatistics,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails $RecipientTypeDetails `
    -Properties WhenCreated, ArchiveStatus, LitigationHoldEnabled, RetentionPolicy, HiddenFromAddressListsEnabled, ForwardingSmtpAddress, AccountDisabled
$i = 0
$rows = foreach ($m in $mailboxes) {
    $i++
    $stats = $null
    if (-not $SkipStatistics) {
        Write-Progress -Activity 'Mailbox statistics' -Status $m.UserPrincipalName -PercentComplete (100 * $i / @($mailboxes).Count)
        $stats = Get-EXOMailboxStatistics -Identity $m.ExternalDirectoryObjectId -Properties LastLogonTime -ErrorAction SilentlyContinue
    }
    [pscustomobject]@{
        DisplayName           = $m.DisplayName
        UserPrincipalName     = $m.UserPrincipalName
        PrimarySmtpAddress    = $m.PrimarySmtpAddress
        Type                  = $m.RecipientTypeDetails
        AccountDisabled       = $m.AccountDisabled
        Created               = $m.WhenCreated
        ArchiveStatus         = $m.ArchiveStatus
        LitigationHold        = $m.LitigationHoldEnabled
        RetentionPolicy       = $m.RetentionPolicy
        HiddenFromGAL         = $m.HiddenFromAddressListsEnabled
        ForwardingSmtpAddress = $m.ForwardingSmtpAddress
        ItemCount             = $stats.ItemCount
        TotalItemSize         = "$($stats.TotalItemSize)"
        LastLogonTime         = $stats.LastLogonTime
    }
}
Write-Progress -Activity 'Mailbox statistics' -Completed
$file = Join-Path $OutputFolder "MailboxInventory-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
$rows | Group-Object Type | Select-Object Name, Count | Out-String | Write-Information -InformationAction Continue
Write-Information "Mailboxes: $(@($rows).Count) -> $file" -InformationAction Continue
