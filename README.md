<div align="center">

<img src="./assets/repologo.png" alt="claude-agentic-email" width="420" />

# claude-agentic-email

**An email channel for [Claude Code](https://code.claude.com) — bring an [agentic-inbox](https://github.com/cloudflare/agentic-inbox) mailbox into a live session.**

[![License](https://img.shields.io/github/license/To3Knee/claude-agentic-email?style=flat&color=blue)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-channel-D97757?style=flat&logo=anthropic&logoColor=white)](https://code.claude.com/docs/en/channels)
[![Bun](https://img.shields.io/badge/Bun-runtime-000000?style=flat&logo=bun&logoColor=white)](https://bun.sh)
[![TypeScript](https://img.shields.io/badge/TypeScript-strict-3178C6?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Email_%26_Access-F38020?style=flat&logo=cloudflare&logoColor=white)](https://developers.cloudflare.com/email-service/)

</div>

---

New mail surfaces in your running Claude Code session the **moment it arrives** — as a `<channel source="agentic-email">` event — and you reply in-thread, with attachments and inline images. It's the email sibling of the Telegram channel: instead of going to check an inbox, the inbox comes to you.

```text
 ┌─────────────┐   poll (CF Access)    ┌──────────────────┐   <channel> event   ┌──────────────┐
 │ agentic-    │  ◀──────────────────  │ claude-agentic-  │  ─────────────────▶ │ Claude Code  │
 │ inbox       │  ──────────────────▶  │ email (this)     │  ◀───── reply ───── │ session      │
 └─────────────┘     mail + replies    └──────────────────┘                     └──────────────┘
```

## ✨ Features

- **📥 Inbound** — new mail lands in-session within seconds. Attachments are downloaded to disk and surfaced as paths, so the model can open and read them.
- **📤 Outbound** — reply in-thread with the `reply` tool. Send downloadable file attachments (`files`) and embed images/GIFs **inline in the body** via hosted URLs (`image_urls`).
- **🔁 Session-bound & no-replay** — events arrive only while Claude Code is open, and existing inbox mail is marked *seen* at launch (no replay storm on restart).
- **🛡️ Injection-aware** — email is treated as untrusted data, never as instructions.

## ⚙️ How it works

- **Listening** — the channel polls the mailbox via the agentic-inbox REST API every `EMAIL_POLL_INTERVAL` seconds (default `20`), authenticated through Cloudflare Access with a service token. Self-contained — no tunnel or webhook required.
- **Replying** — the `reply` tool POSTs through the same API. Pass `email_id` from the inbound `<channel>` block and the subject + threading headers are filled in automatically.

## 🔐 Security

Email content is **untrusted input**. The body is relayed as channel *data*, never as instructions, and the channel tells the model to refuse acting on commands embedded in email (forwarding, payments, settings, secrets) without the operator's say-so from the terminal. Sender-controlled strings that land in the `<channel>` meta are sanitized so they can't forge tag attributes. Inbound attachments are likewise untrusted data.

## 📋 Prerequisites

- An [agentic-inbox](https://github.com/cloudflare/agentic-inbox) deployment with a mailbox, fronted by [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/policies/access/) with a **service token** for non-interactive API auth.
- For sending: the domain onboarded to **Cloudflare Email Service → Email Sending** (DKIM + SPF on `cf-bounce`, plus a `_dmarc` record). Without proper authentication, strict providers — notably Microsoft/Outlook — silently drop mail.
- [Bun](https://bun.sh) installed.

## 🚀 Setup

**1. Configure.** Copy `.env.example` to `~/.claude/channels/agentic-email/.env` and fill it in, or run the helper:

```bash
AGENTIC_INBOX_BASE=https://inbox.example.com \
AGENTIC_INBOX_MAILBOX=assistant@example.com \
CF_ACCESS_CLIENT_ID=xxx CF_ACCESS_CLIENT_SECRET=yyy \
bash install.sh
```

> [!NOTE]
> The `.env` is written mode `600` — it holds a secret.

**2. Register this directory as a plugin marketplace** (one time). The marketplace is named `claude-agentic-email` (see `.claude-plugin/marketplace.json`):

```bash
claude plugin marketplace add /path/to/claude-agentic-email
```

**3. Launch Claude Code with the channel.** Custom channels aren't on the preview allowlist, so the dev flag is required (it only skips the allowlist):

```bash
claude --dangerously-load-development-channels plugin:agentic-email@claude-agentic-email
```

## 🔧 Configuration

All settings come from environment variables (or the `.env` above — real env wins).

| Variable | Required | Default | Purpose |
|---|:---:|---|---|
| `AGENTIC_INBOX_BASE` | ✅ | — | Worker base URL (no trailing slash) |
| `AGENTIC_INBOX_MAILBOX` | ✅ | — | Mailbox to watch and send from |
| `CF_ACCESS_CLIENT_ID` | ✅ | — | CF Access service-token id |
| `CF_ACCESS_CLIENT_SECRET` | ✅ | — | CF Access service-token secret |
| `AGENTIC_INBOX_FROM_NAME` | | `Assistant` | Display name on outbound mail |
| `EMAIL_POLL_INTERVAL` | | `20` | Seconds between inbox polls |

## ⚠️ Notes & limitations

- **Inline images use hosted URLs, not `cid:` attachments.** Cloudflare's Email Service binding does not build the `multipart/related` MIME that clients need to render `cid:` inline images, so embedding is done via `<img src="https://…">` (which Gmail and Outlook both render). Local files can be sent as attachments but cannot be embedded in the body.
- **Polling, ~20s latency.** A webhook-push variant is a natural future addition.

## 🗺️ Roadmap

- [ ] **Webhook delivery** — swap polling for an HMAC-verified push for instant (<1s) delivery.

## 📄 License

[Apache-2.0](./LICENSE) · built on top of [agentic-inbox](https://github.com/cloudflare/agentic-inbox) (Cloudflare).
