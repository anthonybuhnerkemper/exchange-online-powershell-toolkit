#Requires -Version 7.4
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Finds mailbox-level forwarding and inbox rules that forward, redirect, or delete mail.
.DESCRIPTION
    Requires Connect-ExchangeOnline. Checks ForwardingSmtpAddress / ForwardingAddress on each
    mailbox and every inbox rule with ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage
    or MoveToFolder set to RSS/Deleted Items (common compromise patterns). External targets are
    flagged by comparing against accepted domains. Read-only.
.PARAMETER Identity
    Optional list of mailboxes. Defaults to all user and shared mailboxes.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-InboxRuleForwardingAudit.ps1
.EXAMPLE
    ./Get-InboxRuleForwardingAudit.ps1 -Identity user1@contoso.com
#>
[CmdletBinding()]
param(
    [string[]]$Identity,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$accepted = (Get-AcceptedDomain).DomainName
function Test-External([string]$Address) {
    if ($Address -match '(?i)smtp:([^\]"\s]+@([^\]"\s]+))') { return ($Matches[2] -notin $accepted) }
    return $false
}

$mailboxes = if ($Identity) { $Identity | ForEach-Object { Get-EXOMailbox -Identity $_ -Properties ForwardingSmtpAddress, ForwardingAddress, DeliverToMailboxAndForward } }
             else { Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox, SharedMailbox -Properties ForwardingSmtpAddress, ForwardingAddress, DeliverToMailboxAndForward }

$rows = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($m in $mailboxes) {
    $i++
    Write-Progress -Activity 'Inbox rules' -Status $m.PrimarySmtpAddress -PercentComplete (100 * $i / @($mailboxes).Count)
    if ($m.ForwardingSmtpAddress -or $m.ForwardingAddress) {
        $rows.Add([pscustomobject]@{
            Mailbox = $m.PrimarySmtpAddress; Source = 'MailboxForwarding'; RuleName = ''; Enabled = $true
            Action = "Forward (keep copy: $($m.DeliverToMailboxAndForward))"; Target = "$($m.ForwardingSmtpAddress)$($m.ForwardingAddress)"
            External = (Test-External "$($m.ForwardingSmtpAddress)")
        })
    }
    $rules = Get-InboxRule -Mailbox $m.ExternalDirectoryObjectId -ErrorAction SilentlyContinue
    foreach ($r in $rules) {
        $targets = @($r.ForwardTo) + @($r.ForwardAsAttachmentTo) + @($r.RedirectTo) | Where-Object { $_ }
        $suspiciousMove = $r.MoveToFolder -match 'RSS|Deleted Items|Archive|Conversation History'
        if ($targets -or $r.DeleteMessage -or $suspiciousMove) {
            $actions = @()
            if ($r.ForwardTo) { $actions += 'ForwardTo' }
            if ($r.ForwardAsAttachmentTo) { $actions += 'ForwardAsAttachment' }
            if ($r.RedirectTo) { $actions += 'RedirectTo' }
            if ($r.DeleteMessage) { $actions += 'Delete' }
            if ($suspiciousMove) { $actions += "MoveTo:$($r.MoveToFolder)" }
            $rows.Add([pscustomobject]@{
                Mailbox = $m.PrimarySmtpAddress; Source = 'InboxRule'; RuleName = $r.Name; Enabled = $r.Enabled
                Action = $actions -join ','; Target = $targets -join '; '
                External = [bool]($targets | Where-Object { Test-External $_ })
            })
        }
    }
}
Write-Progress -Activity 'Inbox rules' -Completed
$file = Join-Path $OutputFolder "ForwardingAudit-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Findings: $($rows.Count) (external: $(@($rows | Where-Object External).Count)) -> $file" -InformationAction Continue
