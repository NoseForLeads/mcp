# Example: fetching results with verification receipts

A `fetch_results` call against a finished campaign. Domains are illustrative;
the shape and fields are real.

```json
// call
{ "name": "fetch_results",
  "arguments": { "job_id": "job_8f2a1c", "kept_only": false, "limit": 2 } }

// response (2 of 96 rows)
{
  "summary": {
    "total_discovered": 142, "sourced": 96, "needs_review": 11,
    "removed_reasons": { "no_verified_email": 31, "out_of_credits": 4 }
  },
  "total": 96, "credits_spent": 96,
  "rows": [
    { "id": 1042, "domain": "riverside-plumbing.example",
      "email": "info@riverside-plumbing.example",
      "match_status": "validated", "rejection_reason": null,
      "verified_by": "zerobounce", "verifier_verdict": "valid" },
    { "id": 1043, "domain": "oakvalley-plumbing.example",
      "email": null, "match_status": "needs_review",
      "rejection_reason": "no_verified_email",
      "verified_by": null, "verifier_verdict": null }
  ]
}
```

What to notice:

- Row 1042 carries a **verification receipt**: `verified_by` names the
  verifier and `verifier_verdict` its result. The email was checked against
  the live mailbox provider before delivery.
- Row 1043 shows the honest failure path: no verified email was found, so the
  row is flagged `needs_review` with the reason, and it did not cost a credit.
- `summary.removed_reasons` is the campaign-level receipt: every discovered
  business that didn't become a lead is accounted for by reason.
