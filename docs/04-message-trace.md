# 04 - Mail flow and message trace

```powershell
./scripts/MailFlow/Get-MessageTraceReport.ps1 -RecipientAddress user1@contoso.com -Hours 24
./scripts/MailFlow/Get-MessageTraceReport.ps1 -SenderAddress partner@fabrikam.com -Status Failed -Hours 72
```

## Notes
- `Get-MessageTraceV2` replaces `Get-MessageTrace` (retired in 2025). The script falls back to the old cmdlet if needed.
- One query may cover up to 10 days; data is kept for 90 days. For older data use `Start-HistoricalSearch`.
- Statuses: `Delivered`, `Failed`, `Pending`, `Quarantined`, `FilteredAsSpam`, `Expanded` (distribution group expansion).
- For one message's hops: `Get-MessageTraceDetailV2 -MessageTraceId <id> -RecipientAddress <address>`.
