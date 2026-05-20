# claude-agentic-email — an email channel for Claude Code

A Claude Code [channel](https://code.claude.com/docs/en/channels) that pushes
inbound email from an [agentic-inbox](https://github.com/cloudflare/agentic-inbox)
mailbox into the running session as `<channel source="agentic-email">` events,
and exposes a `reply` tool to answer in-thread — including **attachments** and
**inline images**.

It's the email equivalent of the Telegram channel: new mail surfaces in-session
(and on whatever device is watching the session) the moment it arrives, instead
of you having to go check an inbox.

## What you get

- **Inbound** — new mail arrives in-session within seconds. Attachments are
  downloaded to disk and surfaced as paths, so the model can open and read them.
- **Outbound** — reply in-thread with the `reply` tool. Send downloadable file
  attachments (`files`) and embed images/GIFs inline in the body via hosted URLs
  (`image_urls`).
- **Session-bound & no-replay** — events only arrive while Claude Code is open,
  and existing inbox mail is marked seen at launch (no replay storm on restart).

## How it works

- **Listening:** the channel polls the mailbox via the agentic-inbox REST API
  every `EMAIL_POLL_INTERVAL` seconds (default 20), authenticated through
  Cloudflare Access with a service token. Self-contained — no tunnel or webhook.
- **Replying:** the `reply` tool POSTs through the same API. Pass `email_id` from
  the inbound `<channel>` block and subject + threading headers are filled in.

## Security

Email content is **untrusted input**. The body is relayed as channel *data*,
never as instructions, and the channel tells the model to refuse acting on
commands embedded in email (forwarding, payments, settings, secrets) without the
operator's say-so from the terminal. Sender-controlled strings that land in the
`<channel>` meta are sanitized so they can't forge tag attributes. Inbound
attachments are likewise untrusted data.

## Prerequisites

- An [agentic-inbox](https://github.com/cloudflare/agentic-inbox) deployment with
  a mailbox, fronted by [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/policies/access/)
  with a **service token** for non-interactive API auth.
- For sending: the domain onboarded to **Cloudflare Email Service → Email Sending**
  (DKIM + SPF on `cf-bounce`, plus a `_dmarc` record). Without proper
  authentication, strict providers (notably Microsoft/Outlook) silently drop mail.
- [Bun](https://bun.sh) installed.

## Setup

1. **Configure.** Copy `.env.example` to `~/.claude/channels/agentic-email/.env`
   and fill it in, or run the helper:
   ```bash
   AGENTIC_INBOX_BASE=https://inbox.example.com \
   AGENTIC_INBOX_MAILBOX=assistant@example.com \
   CF_ACCESS_CLIENT_ID=xxx CF_ACCESS_CLIENT_SECRET=yyy \
   bash install.sh
   ```
   The `.env` is written mode `600` (it holds a secret).

2. **Register this directory as a plugin marketplace** (one time). The
   marketplace is named `claude-agentic-email` (see `.claude-plugin/marketplace.json`):
   ```bash
   claude plugin marketplace add /path/to/claude-agentic-email
   ```

3. **Launch Claude Code with the channel.** Custom channels aren't on the
   preview allowlist, so the dev flag is required (it only skips the allowlist):
   ```bash
   claude --dangerously-load-development-channels plugin:agentic-email@claude-agentic-email
   ```

## Configuration

All settings come from env vars (or the `.env` above — real env wins).

| Var | Required | Default | Purpose |
|---|:---:|---|---|
| `AGENTIC_INBOX_BASE` | ✓ | — | Worker base URL (no trailing slash) |
| `AGENTIC_INBOX_MAILBOX` | ✓ | — | Mailbox to watch and send from |
| `CF_ACCESS_CLIENT_ID` | ✓ | — | CF Access service-token id |
| `CF_ACCESS_CLIENT_SECRET` | ✓ | — | CF Access service-token secret |
| `AGENTIC_INBOX_FROM_NAME` | | `Assistant` | Display name on outbound mail |
| `EMAIL_POLL_INTERVAL` | | `20` | Seconds between inbox polls |

## Notes & limitations

- **Inline images use hosted URLs, not `cid:` attachments.** Cloudflare's Email
  Service binding does not build the `multipart/related` MIME that clients need to
  render `cid:` inline images, so embedding is done via `<img src="https://…">`
  (which Gmail and Outlook both render). Local files can be sent as attachments
  but cannot be embedded in the body.
- **Polling, ~20s latency.** A webhook-push variant is a natural future addition.

## License

[Apache-2.0](./LICENSE).
