# 01 - Install ExchangeOnlineManagement v3 and connect

## 1. Install or update
```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser        # 3.7 or later recommended
Update-Module ExchangeOnlineManagement
Get-Module ExchangeOnlineManagement -ListAvailable | Select-Object Version
```
Version 3 uses REST for all cmdlets, so basic auth and WinRM are not needed. `Get-MessageTraceV2` needs 3.7+.

## 2. Connect interactively
```powershell
. ./scripts/Connect/Connect-M365Admin.ps1
Connect-M365Admin -Service ExchangeOnline -Interactive -UserPrincipalName admin@contoso.onmicrosoft.com
```

## 3. Connect with a certificate (app-only)
1. Create an Entra app registration and upload a certificate public key.
2. API permissions: **Office 365 Exchange Online > Application > Exchange.ManageAsApp**, then grant admin consent.
3. Assign the app's service principal an Entra role (for example **Exchange Recipient Administrator**, or **Global Reader** for read-only reports).
```powershell
$env:M365_TENANT_ID       = '00000000-0000-0000-0000-000000000000'
$env:M365_CLIENT_ID       = '00000000-0000-0000-0000-000000000000'
$env:M365_CERT_THUMBPRINT = '<thumbprint>'
$env:M365_ORGANIZATION    = 'contoso.onmicrosoft.com'
Connect-M365Admin -Service ExchangeOnline
```
`Get-UnlicensedMailboxReport` also needs Graph: `Connect-M365Admin -Service Graph, ExchangeOnline`.

## 4. Verify
```powershell
Get-ConnectionInformation | Select-Object UserPrincipalName, TenantID, State
Get-EXOMailbox -ResultSize 5
```
