#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Exports calendar folder permissions (Default, Anonymous and named delegates) for mailboxes.
.DESCRIPTION
    Requires Connect-ExchangeOnline. The calendar folder name is resolved per mailbox, so
    non-English mailboxes work. Read-only.
.PARAMETER Identity
    Optional list of mailboxes. Defaults to all user, shared and room mailboxes.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-CalendarPermissionReport.ps1
.EXAMPLE
    ./Get-CalendarPermissionReport.ps1 -Identity room-boardroom@contoso.com
#>
[CmdletBinding()]
param(
    [string[]]$Identity,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$mailboxes = if ($Identity) { $Identity | ForEach-Object { Get-EXOMailbox -Identity $_ } }
             else { Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox, SharedMailbox, RoomMailbox }
$rows = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($m in $mailboxes) {
    $i++
    Write-Progress -Activity 'Calendar permissions' -Status $m.PrimarySmtpAddress -PercentComplete (100 * $i / @($mailboxes).Count)
    $cal = Get-EXOMailboxFolderStatistics -Identity $m.ExternalDirectoryObjectId -FolderScope Calendar |
        Where-Object FolderType -eq 'Calendar' | Select-Object -First 1
    if (-not $cal) { continue }
    $folderId = "$($m.PrimarySmtpAddress):\$($cal.Name)"
    foreach ($p in Get-EXOMailboxFolderPermission -Identity $folderId -ErrorAction SilentlyContinue) {
        $rows.Add([pscustomobject]@{
            Mailbox      = $m.PrimarySmtpAddress
            Type         = $m.RecipientTypeDetails
            Folder       = $cal.Name
            User         = "$($p.User)"
            AccessRights = ($p.AccessRights -join ',')
            SharingFlags = ($p.SharingPermissionFlags -join ',')
        })
    }
}
Write-Progress -Activity 'Calendar permissions' -Completed
$file = Join-Path $OutputFolder "CalendarPermissions-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Entries: $($rows.Count) -> $file" -InformationAction Continue
