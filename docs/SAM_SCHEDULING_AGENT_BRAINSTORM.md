# Scheduling Agent brainstorm

> Author: Sam. Status: brainstorm / future architecture. None of the behavior
> below is implemented by the current agent skeleton.


Invariants:

- **Every frontmatter field can be rebuilt** from the log plus the sources the
  log links. A sweep re-reads the evidence and rewrites the fields, so drift
  corrects itself.
- **Every log line cites a source**: an email thread, a Plow message, or a
  calendar event.
- **`pipelines/<pipeline>.md` is generated** by `wiki index` after every
  relationship write, from the table `scheduling/_schema.md` declares (sorted by
  `due`, grouped by `stage`). It carries `generated: true`; nobody edits it by hand.
- **A note that fails `wiki validate` is never guessed at.** The agent skips it
  and names its path in the brief.

**Pipelines.** The fundraising `_pipeline.md` ships as a template, with stages
`prospect → contacted → scheduling → met → diligence → committed | passed`.
"Start a hiring pipeline" creates a new `_pipeline.md` with default stages
(`sourced → contacted → scheduling → interviewed → offer → hired | passed`),
which the owner confirms in chat.

## 3. Platform contract: plow-wiki

The wiki is a generic store for every agent type, not a scheduling feature.
[plow-wiki](https://github.com/plow-pbc/plow-wiki) owns its contract (its
`skill.md` and `AGENTS.md`); where this section and plow-wiki differ, plow-wiki
wins. This agent depends only on the following.

| Need | How |
|---|---|
| Read and write notes | `plow_read_file` / `plow_write_file` under `~/Plow/wiki` through Latch (auto-approved inside `~/Plow`) |
| Validate, render tables, keep history | `plow_run_command(["wiki", …])`: `validate`, `index`, `snapshot`, `history <path>` |
| Find a note | Index-first: `index.md` lists every page with its summary. No full-text search in v1 |
| Past versions | `wiki history <path>`: commits touching the note, with author and time, from a bare repo beside the wiki |

**Ownership.** `wiki.toml` names one writer per root. It is a declared
convention that `wiki snapshot` enforces by refusing undeclared roots, not a
credential grant.

**Consistency.** No compare-and-swap: on a filesystem a version check is advisory
at best. Every turn reads a note immediately before it acts on or writes it (§4).

**Human surface.** The owner opens the wiki in Obsidian and may edit any page;
an agent write preserves what the agent did not produce. Generated files are not
edited by hand.

**Portability.** Plain Markdown with YAML frontmatter; the folder is an Obsidian
vault.

**Non-goals.** No query engine, no embeddings, no Plow-hosted rendering in v1.

## 4. Evidence and the always-on loop

**Evidence sources.** Only the agent's own channels are written to.

- The agent's own Plow text line and mailbox: inbound is pushed instantly.
- The principal's Gmail through Latch: always the full thread, never only its
  first message.
- Every calendar in `constraints.md`, through Latch.
- The principal's Messages, where Latch exposes them, to catch outreach the
  principal sent personally.

**Triggers.**

1. **Inbound on the agent's own line or mailbox** starts a turn for that
   relationship immediately.
2. **The sweep** runs every 3 hours in the principal's working hours, plus once
   overnight. For each relationship not in `idle`, and each with `due` today or
   earlier, it reads the evidence since `last_touch`, appends log lines, rebuilds
   the frontmatter, and regenerates the pipeline tables. New meeting asks, and
   invites or booking links sent to the principal, enter `requested` like any
   other request. The owner sees proposed slots, and nothing reaches the
   counterparty without owner OK (§1).
3. **The morning brief** is sent to the owner at `brief_time`:
   - **Today:** meetings on every calendar, each with a one-line prep note from
     its relationship note.
   - **Needs your OK:** numbered slots per relationship; a reply of `1 3`
     approves those.
   - **Waiting on them:** days since the offer, and which nudges go out today.
   - **Releasing tomorrow:** holds about to expire.
   - **Overdue:** relationships past `due`, with a link to the pipeline note.
4. **A reminder** goes to the owner 15 minutes before any meeting the agent
   booked.

**Consistency across sessions.** Every turn that touches a relationship, in any
session or channel, re-reads the note immediately before it sends anything or
writes. No message goes to a counterparty until the turn has read the note's
current state. The observed failure (a group-thread session contradicting the
direct chat) was a session acting without reading state, which a fresh read
prevents. v1 has no version check (§3), so two writes landing within the same
seconds remain possible; that is accepted at this scale.

**Failing loudly.**

- **Stale calendars:** no offer or booking without a calendar read less than 10
  minutes old. The wiki sits on the same Mac, so the pipeline goes stale with
  the calendars and the brief says so for both. If Latch is unreachable (for example, the owner's Mac is asleep),
  the agent tells the owner "can't see calendars since 2:10pm" and the brief
  repeats it.
- **Missed sweeps:** if no sweep has finished in 6 hours, the next brief or reply
  says so.
- **Invalid notes:** frontmatter that fails validation is named by path in the
  brief.

## 5. Packaging and components

The calendaring capability ships as a **skill pack** installable into any Plow
Hermes agent. The standalone calendaring agent is thin: `FROM plow-hermes-agent`,
plus a persona, the skill pack, and cron entries for the sweep and the brief.
The single-writer rule holds wherever the pack is installed, because `wiki.toml`
names one writer for `scheduling/`.

| Skill | Responsibility | Deterministic, tested code |
|---|---|---|
| `calendar-basics` | Find free time across calendars and constraints; invites; reminders. Used by any agent | Business-day arithmetic, free/busy conflict check ignoring the agent's own hold, hold marker read/write |
| `scheduling-lifecycle` | §1 states and rules | State transition table, hold expiry |
| `relationship-wiki` | §2 `scheduling/_schema.md`, log conventions, rebuilding fields | None of its own: validation and table rendering are `wiki validate` and `wiki index` |
| `sweep` + `morning-brief` | §4 loop | Brief assembly, parsing approval replies (`1 3`, `none`, a named slot) |

The model reads threads, decides what the evidence means, and drafts messages.
Scripts do everything that has to be exact.

**Tools used:** `plow_send_message` and the agent's mailbox line; plow-gog through
Latch (Gmail threads; calendar events, create, update, delete); the owner's
plow-wiki (§3); Hermes cron.

**Migration.** A one-time import turns the existing investor CSV into
relationship notes, and the history reconstructed from the current agent's
transcripts seeds their logs. After import, the Founder Agent's
`investor-pipeline` and `founder-scheduling` skills and the life assistant's
scheduling duties are retired.

## 6. Testing

1. **Unit tests** cover the deterministic scripts in §5, asserting behavior only.
2. **Replay scenarios** come from the August–September 2026 investor history,
   anonymized. Latch and Plow are faked at their boundaries. Each scenario
   asserts the end artifact (the note's state and fields, the calendar
   operations issued, the outbound message), never the agent's summary:
   - A counterparty accepts a time in a text thread → booked, and confirmed
     within the same turn.
   - A counterparty's scheduler proposes a window → `awaiting_owner`, not booked.
   - The owner's reply sits deeper in an email thread than the first message →
     the sweep logs it, and the status is right.
   - A slot overlaps a hard block → never offered.
   - Another agent's hold has the same title → left untouched.
   - Two relationships would be offered the same slot → the second is not offered
     that slot while it is held.
   - Latch unreachable at booking time → no booking, and the owner is told.
   - A counterparty confirms after a new conflict appears → not booked; fresh
     slots go to the owner.
   - Silence for 3 business days → exactly one nudge; at 5 business days the
     holds are released.
3. **Live acceptance:** one real round on the founder's own calendar, from
   request to booked invite, verified against the actual calendar event and the
   generated pipeline table in the owner's wiki.

## Out of scope for v1

- A tiered request policy (VIP, known, unknown).
- One EA serving several principals.
- Booking through a counterparty's booking link (v1 sends the owner the link
  plus suggested slots).
- Signature, wire, or other deal logistics.
- A Plow-hosted view of the wiki (rendering in the account app).

## Future

- **Per-agent wikis.** A root is already the unit of ownership, so a per-agent
  wiki is a wiki declaring a single root.
- **Cross-account per-principal wikis.** An EA's agent and the principal's own
  agents write to one wiki. A wiki lives on one Mac behind one owner's Latch, so
  this needs a transport beyond it.
- **Tiered request policy**, stored in `constraints.md`.

## Open questions

- **Calendar reachability for cloud agents.** Every Google read goes through
  Latch on the owner's Mac. §4 makes it fail loudly, but an owner whose Mac is
  often asleep gets a degraded agent. With Latch's Google scopes frozen, the
  long-term path is unresolved.
- **Messages evidence.** Whether Latch exposes the principal's Messages to cloud
  agents consistently enough to be a sweep source, or only opportunistically.
- **Mailbox provisioning.** Whether every owner's agent can get its own mailbox
  line at install, or only a text line.
- **One Mac, two dependencies.** Calendar reads and the pipeline both go
  through Latch on the owner's Mac, so a sleeping Mac degrades the sweep and the
  brief together. §4 fails loudly; whether that is acceptable for an EA whose
  principal's Mac is often asleep is unresolved.
