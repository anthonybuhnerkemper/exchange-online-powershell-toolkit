# Exchange Online PowerShell Toolkit

A practical toolkit and step-by-step guide for administering **Exchange Online** with **PowerShell 7** and **ExchangeOnlineManagement v3** (REST-based `Get-EXO*` cmdlets).

It covers mailbox inventory, shared mailbox and permission audits, inbox rule and forwarding audits, message trace, distribution group reports, license-based mailbox cleanup, and calendar permissions. Every script has comment-based help (`Get-Help ./script.ps1 -Full`), reports export to CSV, and every change script supports `-WhatIf` / `-Confirm`. Authentication uses **certificates** (app-only) or **interactive** sign-in via the same `Connect-M365Admin` pattern as [graph-powershell7-admin-toolkit](https://github.com/anthonybuhnerkemper/graph-powershell7-admin-toolkit). No secrets are stored in the repo.

> ⚠️ **Disclaimer:** Test everything in a non-production / developer tenant first. Examples use `contoso.com`, `contoso.onmicrosoft.com`, and placeholder GUIDs (`00000000-0000-0000-0000-000000000000`). Review each script before running it in your environment.

## Prerequisites

| Requirement | Version / notes |
|---|---|
| PowerShell | 7.4 or later (`pwsh`) |
| ExchangeOnlineManagement | 3.7 or later (for `Get-MessageTraceV2`) |
| Microsoft.Graph.Users | 2.x, only for `Get-UnlicensedMailboxReport` |
| Roles | Global Reader / View-Only Organization Management for reports; Exchange Administrator for changes |

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
```

## Quick start

```powershell
git clone https://github.com/anthonybuhnerkemper/exchange-online-powershell-toolkit.git
cd exchange-online-powershell-toolkit

. ./scripts/Connect/Connect-M365Admin.ps1
Connect-M365Admin -Service ExchangeOnline -Interactive -UserPrincipalName admin@contoso.onmicrosoft.com

# Reports (CSV files land in ./output)
./scripts/Mailboxes/Get-EXOMailboxInventory.ps1
./scripts/Security/Get-InboxRuleForwardingAudit.ps1
./scripts/MailFlow/Get-MessageTraceReport.ps1 -Status Failed -Hours 24

# Preview a change before applying it
./scripts/Cleanup/Convert-MailboxToShared.ps1 -Identity former.user@contoso.com -WhatIf

. ./scripts/Connect/Disconnect-M365Admin.ps1
Disconnect-M365Admin
```

## Repo map

```text
.github/workflows/pssa.yml  PSScriptAnalyzer CI on push and PR
docs/
  01-install-and-connect-exchange-online.md
  02-mailbox-inventory-and-permissions.md
  03-inbox-rules-and-forwarding.md
  04-message-trace.md
  05-distribution-groups-and-mailbox-cleanup.md
  06-calendar-permissions.md
scripts/
  Connect/      Connect-M365Admin.ps1, Disconnect-M365Admin.ps1
  Mailboxes/    Get-EXOMailboxInventory
  Permissions/  Get-SharedMailboxPermissionAudit
  Security/     Get-InboxRuleForwardingAudit
  MailFlow/     Get-MessageTraceReport
  Groups/       Get-DistributionGroupReport
  Cleanup/      Get-UnlicensedMailboxReport, Convert-MailboxToShared
  Calendar/     Get-CalendarPermissionReport, Set-CalendarDefaultPermission
```

## Permissions

App-only use needs the `Exchange.ManageAsApp` application permission plus an Entra role on the service principal.

| Script | Minimum role | Changes? |
|---|---|---|
| Get-EXOMailboxInventory | Global Reader / View-Only Recipients | No |
| Get-SharedMailboxPermissionAudit | Global Reader / View-Only Recipients | No |
| Get-InboxRuleForwardingAudit | Exchange Administrator (Get-InboxRule needs mailbox access) | No |
| Get-MessageTraceReport | Global Reader / Message Tracking role | No |
| Get-DistributionGroupReport | Global Reader / View-Only Recipients | No |
| Get-UnlicensedMailboxReport | Global Reader + Graph `User.Read.All` | No |
| Convert-MailboxToShared | Exchange Recipient Administrator | Yes (`-WhatIf`) |
| Get-CalendarPermissionReport | Exchange Administrator | No |
| Set-CalendarDefaultPermission | Exchange Recipient Administrator | Yes (`-WhatIf`) |

## Related

- [graph-powershell7-admin-toolkit](https://github.com/anthonybuhnerkemper/graph-powershell7-admin-toolkit): Exchange security baseline, transport and anti-phish reports
- [purview-compliance-toolkit](https://github.com/anthonybuhnerkemper/purview-compliance-toolkit): retention, eDiscovery and audit log search

## License

[MIT](LICENSE) © 2026 Anthony Buhnerkemper
