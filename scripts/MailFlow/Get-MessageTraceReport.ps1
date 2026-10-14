#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Runs a message trace for the last N hours/days and exports the results to CSV.
.DESCRIPTION
    Requires Connect-ExchangeOnline (ExchangeOnlineManagement 3.7+ for Get-MessageTraceV2).
    Falls back to the legacy Get-MessageTrace if V2 is unavailable. Message trace data covers the
    last 90 days; one query may span at most 10 days. Read-only.
.PARAMETER SenderAddress
    Filter by sender.
.PARAMETER RecipientAddress
    Filter by recipient.
.PARAMETER Status
    Filter by delivery status, for example Failed, Quarantined, FilteredAsSpam, Delivered.
.PARAMETER Hours
    How far back to search. Default 48, maximum 240 (10 days).
.PARAMETER ResultSize
    Maximum rows (1-5000). Default 5000.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-MessageTraceReport.ps1 -RecipientAddress user1@contoso.com -Hours 24
.EXAMPLE
    ./Get-MessageTraceReport.ps1 -Status Failed -Hours 72
#>
[CmdletBinding()]
param(
    [string]$SenderAddress,
    [string]$RecipientAddress,
    [ValidateSet('None', 'GettingStatus', 'Failed', 'Pending', 'Delivered', 'Expanded', 'Quarantined', 'FilteredAsSpam')]
    [string]$Status,
    [ValidateRange(1, 240)][int]$Hours = 48,
    [ValidateRange(1, 5000)][int]$ResultSize = 5000,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$traceParams = @{ StartDate = (Get-Date).ToUniversalTime().AddHours(-$Hours); EndDate = (Get-Date).ToUniversalTime() }
if ($SenderAddress) { $traceParams.SenderAddress = $SenderAddress }
if ($RecipientAddress) { $traceParams.RecipientAddress = $RecipientAddress }
if ($Status) { $traceParams.Status = $Status }

if (Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue) {
    $results = Get-MessageTraceV2 @traceParams -ResultSize $ResultSize
}
else {
    Write-Warning 'Get-MessageTraceV2 not found; using legacy Get-MessageTrace. Update ExchangeOnlineManagement.'
    $results = Get-MessageTrace @traceParams -PageSize $ResultSize
}

$rows = $results | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, Size, FromIP, ToIP, MessageId, MessageTraceId
$file = Join-Path $OutputFolder "MessageTrace-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
$rows | Group-Object Status | Select-Object Name, Count | Out-String | Write-Information -InformationAction Continue
Write-Information "Messages: $(@($rows).Count) -> $file" -InformationAction Continue
