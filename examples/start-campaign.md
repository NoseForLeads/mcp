# Example: free text → structured query → campaign

The submit path is always two steps: `translate_icp` turns free text into a
structured query, then `start_campaign` submits it. `start_campaign` never
accepts free text — pass `translate_icp`'s `vertical`, `geo`, and `query`
fields straight through. Values are illustrative; the shapes are real.

```json
// 1) translate the ICP
{ "name": "translate_icp",
  "arguments": { "text": "plumbers in phoenix with no website, independents only" } }

// response — pass vertical/geo/query straight to start_campaign
{
  "vertical": "plumbers",
  "geo": "phoenix, az",
  // query: the structured filter dict the translator built; treat it as
  // opaque and pass it through unchanged
  "query": { "...": "structured filters" },
  "preview": "Plumbers in Phoenix, AZ with no website, independents only",
  "unsupported": []
}
```

```json
// 2) submit, with an idempotency key so a retry can never double-charge
{ "name": "start_campaign",
  "arguments": {
    "vertical": "plumbers",
    "geo": "phoenix, az",
    "query": { "...": "structured filters, passed through" },
    "idempotency_key": "phx-plumbers-2026-07-16"
  } }

// response
{ "job_id": "job_8f2a1c", "idempotent_replay": false }
```

```json
// 3) poll until done, then fetch (see fetch-results.md)
{ "name": "get_campaign_status", "arguments": { "job_id": "job_8f2a1c" } }

// response
{ "job_id": "job_8f2a1c", "status": "running" }
```

What to notice:

- `unsupported` lists any part of the free text the translator could not turn
  into a filter, so nothing is silently dropped.
- Retrying step 2 with the same `idempotency_key` returns the original
  campaign with `idempotent_replay: true` instead of starting (and charging) a
  second one.
- If the account has no verified card yet, `start_campaign` returns a
  `card_required` error carrying a `setup_url` to surface to the user; if the
  balance can't cover everything discovered, the campaign ends `done_partial`
  and delivers what the credits covered. Nothing fails outright and nothing
  overspends.
