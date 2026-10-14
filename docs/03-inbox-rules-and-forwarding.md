# 03 - Inbox rule and forwarding audit

Attackers who compromise a mailbox often create rules that forward mail outside the organization or hide replies (move to RSS Feeds / Deleted Items, or delete).

## 1. Run the audit
```powershell
./scripts/Security/Get-InboxRuleForwardingAudit.ps1
./scripts/Security/Get-InboxRuleForwardingAudit.ps1 -Identity user1@contoso.com
```
The `External` column is `True` when a target's domain is not one of your accepted domains.

## 2. Triage
1. Filter `External = TRUE` first.
2. Confirm with the user whether the rule is expected.
3. Disable a suspicious rule: `Disable-InboxRule -Mailbox user1@contoso.com -Identity '<rule name>'`.
4. If compromise is suspected: reset the password, revoke sessions (`Revoke-MgUserSignInSession`), and review sign-ins.

## 3. Prevent it
- Outbound spam filter policy: set **Automatic forwarding rules** to **Off - Forwarding is disabled**, with exceptions per policy.
- Alert policy "Suspicious email forwarding activity" in Microsoft Defender.
