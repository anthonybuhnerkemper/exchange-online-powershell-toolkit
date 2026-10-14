# 06 - Calendar permissions

## 1. Report
```powershell
./scripts/Calendar/Get-CalendarPermissionReport.ps1
./scripts/Calendar/Get-CalendarPermissionReport.ps1 -Identity room-boardroom@contoso.com
```

## 2. Set the Default level
```powershell
./scripts/Calendar/Set-CalendarDefaultPermission.ps1 -Identity room-boardroom@contoso.com -AccessRights LimitedDetails -WhatIf
```

| Level | What others see |
|---|---|
| None | Nothing |
| AvailabilityOnly | Free/busy (default) |
| LimitedDetails | Free/busy, subject and location |
| Reviewer | Full details read-only |

Delegates: `Add-MailboxFolderPermission -Identity 'exec@contoso.com:\Calendar' -User assistant@contoso.com -AccessRights Editor -SharingPermissionFlags Delegate`.
