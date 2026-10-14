# 02 - Mailbox inventory and shared mailbox permissions

## 1. Inventory
```powershell
./scripts/Mailboxes/Get-EXOMailboxInventory.ps1                       # all types, with size
./scripts/Mailboxes/Get-EXOMailboxInventory.ps1 -SkipStatistics       # fast
```
Columns include type, archive state, litigation hold, retention policy, forwarding, item count, size and last logon.

## 2. Permission audit
```powershell
./scripts/Permissions/Get-SharedMailboxPermissionAudit.ps1            # shared mailboxes
./scripts/Permissions/Get-SharedMailboxPermissionAudit.ps1 -AllMailboxes
```
One row per mailbox, trustee and right (`FullAccess`, `SendAs`, `SendOnBehalf`).

## 3. Review checklist
- Trustees who are disabled or departed users.
- Shared mailboxes with no trustees (orphaned).
- Shared mailboxes where `SendAs` is granted to large groups.
- Remove stale access with `Remove-MailboxPermission` / `Remove-RecipientPermission` after confirmation.
