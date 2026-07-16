# Nose for Leads — MCP server

Verified local-business leads, built for agents.

Nose for Leads is an MCP server that finds, filters, and verifies local-business
leads on demand: agents get back a send-ready list of contacts, not raw scrape
data. Every email carries a machine-readable verification receipt (verifier,
verdict, timestamp) so an agent can act on it without a human double-checking.
Access is credit-based with per-key spend budgets and daily caps, so an agent
can be handed a key without a blank check.

- **Endpoint:** `https://api.noseforleads.com/mcp` (streamable HTTP; OAuth 2.1
  with dynamic client registration, or an `X-API-Key` header)
- **Website:** https://www.noseforleads.com/mcp-server-local-business-leads
- **Full agent guide:** https://www.noseforleads.com/agents.md
- **OpenAPI (REST surface):** https://api.noseforleads.com/openapi.json
- **Sign up (25 free validated leads):** https://app.noseforleads.com/signup

> This repository holds the public integration docs, the registry manifest
> (`server.json`), and example transcripts. The server itself is remote-hosted;
> there is nothing to install or self-host.

## Connect

### Claude Code (OAuth, no key to paste)

```
claude mcp add --transport http nose-for-leads https://api.noseforleads.com/mcp
claude mcp login nose-for-leads
```

`login` opens your browser to approve access and set a spending budget. The
token persists across sessions and refreshes itself.

### Codex CLI

```toml
# ~/.codex/config.toml
[mcp_servers.nose-for-leads]
url = "https://api.noseforleads.com/mcp"
```

```
codex mcp login nose-for-leads
```

If OAuth gives you trouble, the API-key header works in Codex too:
`env_http_headers = { "X-API-Key" = "YOUR_ENV_VAR" }` under the same block.

### Cursor, Windsurf, other MCP clients

Point your client's HTTP server config at `https://api.noseforleads.com/mcp`.
Cursor's `.cursor/mcp.json` (and any client that reads the standard shape):

```json
{
  "mcpServers": {
    "nose-for-leads": { "type": "http", "url": "https://api.noseforleads.com/mcp" }
  }
}
```

### API key (scripts, CI, clients without OAuth)

Mint a key at https://app.noseforleads.com/keys and pass it as a header:
`X-API-Key: <your key>` (or `Authorization: Bearer <your key>`). Keys can carry
a total and/or daily credit budget, so a runaway loop stops at the cap with a
`budget_exhausted` error instead of draining the account.

## Tools

All 9 tools carry MCP tool annotations (readOnly / destructive / idempotent /
openWorld) and require the auth above.

| Tool | What it does |
|---|---|
| `translate_icp` | Turns a free-text ICP description (e.g. "plumbers in phoenix with no website") into the structured `query` dict `start_campaign` requires. Call this first: `start_campaign` never accepts free text. |
| `start_campaign` | Submits a lead campaign for a vertical + geo. Costs 1 credit per validated lead and cannot overspend. Accepts an `idempotency_key` for safe retries. Returns `{job_id, idempotent_replay}`. |
| `get_campaign_status` | Checks a campaign's status by `job_id`: `queued`, `running`, `done`, `done_partial`, or `failed`. |
| `fetch_results` | Pages through a campaign's leads (`offset`/`limit`). `kept_only=true` returns only leads marked kept in review. Rows carry verification receipts when a live verification exists. |
| `get_icp_pack` | Lists saved vertical/geo templates (ICP packs) available to the account. |
| `add_suppression` | Adds an email or domain to the suppression list so future campaigns exclude it. |
| `review_lead` | Marks a lead `kept`, `discarded`, or `unreviewed`. |
| `get_credits` | Checks the prepaid credit balance (1 credit = 1 validated lead), available packs, and recent ledger entries; with an API key, also that key's remaining budget. |
| `send_feedback` | Sends feedback to the Nose for Leads team (`kind: "product"` or `kind: "tool"`). |

## Verification receipts

Rows returned by `fetch_results` carry a receipt when a live verification
exists: `verified_by` (which verifier), `verified_at` (when), and
`verifier_verdict` (the result). A receipt proves the email was checked against
the live mailbox provider, not merely pattern-matched. See
[examples/](examples/) for real transcript shapes.

## Credits and safety semantics

- 1 credit = 1 validated lead; 25 free at signup, prepaid packs from $19.99 for 200.
- A campaign that discovers more leads than the balance covers delivers what
  the credits cover and ends `done_partial` instead of failing.
- Per-key budgets are enforced before the account balance, and
  `start_campaign` honors `idempotency_key`, so a retry never double-charges.
- Errors return a plain `{code, message}` envelope (e.g. `payment_required`,
  `budget_exhausted`, `quota_exceeded` with `retry_after`). The full table is
  in the [agent guide](https://www.noseforleads.com/agents.md).
