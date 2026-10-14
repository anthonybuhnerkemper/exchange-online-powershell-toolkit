#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Reports distribution and mail-enabled security groups: owners, member counts, external
    sender setting, and empty or ownerless groups.
.DESCRIPTION
    Requires Connect-ExchangeOnline. Produces a summary CSV and, with -IncludeMembers, a
    member detail CSV. Read-only.
.PARAMETER IncludeMembers
    Also export one row per group member.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-DistributionGroupReport.ps1 -IncludeMembers
#>
[CmdletBinding()]
param(
    [switch]$IncludeMembers,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$groups = Get-DistributionGroup -ResultSize Unlimited
$summary = [System.Collections.Generic.List[object]]::new()
$members = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($g in $groups) {
    $i++
    Write-Progress -Activity 'Distribution groups' -Status $g.PrimarySmtpAddress -PercentComplete (100 * $i / @($groups).Count)
    $m = @(Get-DistributionGroupMember -Identity $g.Identity -ResultSize Unlimited)
    $summary.Add([pscustomobject]@{
        DisplayName                = $g.DisplayName
        PrimarySmtpAddress         = $g.PrimarySmtpAddress
        Type                       = $g.RecipientTypeDetails
        Owners                     = ($g.ManagedBy -join '; ')
        MemberCount                = $m.Count
        AcceptsExternalSenders     = (-not $g.RequireSenderAuthenticationEnabled)
        HiddenFromGAL              = $g.HiddenFromAddressListsEnabled
        IsDirSynced                = $g.IsDirSynced
        Empty                      = ($m.Count -eq 0)
        NoOwner                    = (-not $g.ManagedBy)
        WhenCreated                = $g.WhenCreated
    })
    if ($IncludeMembers) {
        foreach ($x in $m) { $members.Add([pscustomobject]@{ Group = $g.PrimarySmtpAddress; Member = $x.PrimarySmtpAddress; Name = $x.DisplayName; Type = $x.RecipientTypeDetails }) }
    }
}
Write-Progress -Activity 'Distribution groups' -Completed
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$summary | Export-Csv (Join-Path $OutputFolder "DistributionGroups-$stamp.csv") -NoTypeInformation
if ($IncludeMembers) { $members | Export-Csv (Join-Path $OutputFolder "DistributionGroupMembers-$stamp.csv") -NoTypeInformation }
Write-Information "Groups: $($summary.Count)  Empty: $(@($summary | Where-Object Empty).Count)  No owner: $(@($summary | Where-Object NoOwner).Count)" -InformationAction Continue
