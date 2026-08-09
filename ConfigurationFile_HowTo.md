# Configuring 3270BBS (`tsu.cnf`)

This document catalogues every option 3270BBS reads from `tsu.cnf`: what it does,
whether it is optional, what value is used when it is absent, and what actually
happens when it is wrong.

It is written for the person running the BBS. Where a statement is likely to
surprise you it is still stated plainly, because the surprising cases are the
ones that cost you an evening.

---

## 1. Where the file lives and how it is read

`tsu.cnf` is opened by the **relative** path `tsu.cnf`. There is no search path,
no environment variable, and no command-line override. **The BBS must be started
with its working directory set to the install directory**, or it will not find
its configuration. (The same is true of `tsu.db`, `./templates/`, `./static/`,
and the TLS certificate paths if you give them relative names.)

### Getting a file in the first place

You do not have to write one from scratch. On first start, if `tsu.cnf` is
missing, the BBS runs an interactive setup wizard and writes the file for you.
The same first-run path also offers to create the `tsu.db` database. After that,
`tsu.cnf` is yours to edit by hand; nothing rewrites it behind your back.

### When your edits take effect

Almost everything in `tsu.cnf` is read **once, at startup**. Editing the file
while the BBS is running changes nothing until you restart it.

Three settings are the exception. These are genuinely re-read from disk while
the BBS is running, so editing them takes effect **without a restart**:

- **Remote hosts** (`remoteN` and its sub-keys). The file is re-read every time
  a user paints the remote-host menu. Add, edit or remove a `remoteN` block and
  the next user to open the menu sees the change.
- **`show_logon_stats`.** Re-read on every paint of the logon screen (three
  times per paint, in fact, plus once more when PF2 is pressed). Cheap to change,
  slightly expensive to leave enabled on a busy node.
- **`required_conferences`.** Re-read every time a user tries to unsubscribe
  from a conference. If the re-read fails for any reason, the value the BBS
  started with is used instead.

Several SDSF operations also re-read the whole file, so they are a way to apply
config changes to one service without a full restart:

- `P HTTPD` then `S HTTPD` picks up edited HTTP/HTTPS settings.
- `P FTPD` then `S FTPD` picks up edited FTP settings, including `ftp_limit`.
- `P SMTPD` then `S SMTPD` picks up edited `smtp_domain` and `smtp_port`.
- `S FINGERD` picks up an edited `fingerd_port`.

If a re-read fails for any reason, the service keeps the settings the BBS
started with rather than dropping back to built-in defaults.

One thing these commands deliberately do **not** re-read is the service's own
on/off switch. `S SMTPD` starts SMTPD even when `start_smtpd=no` is in the file,
because you asked it to; the file decides only what happens at the next
startup.

### Syntax rules

- One `key=value` per line. Leading and trailing whitespace is trimmed from the
  line, and from the key and the value independently, so `  port = 3270  ` is
  fine.
- **Key names are case-insensitive.** `start_sshd`, `START_SSHD` and
  `Start_SSHD` are all the same key. Write them lowercase — that is the spelling
  this document and the generated file use — but an inherited file in any other
  casing is read correctly.
- **Comments.** A line whose first non-whitespace character is `#` is skipped
  entirely. **Inline comments work too**, on any unquoted value: a `#` starts a
  comment when it is the first character of the value or when it follows a space
  or a tab. A `#` in the middle of a word is part of the value, so
  `db_password=pa#ss` keeps its `#` intact.
- **Quotes.** A value that begins with `"` is taken literally up to the next
  `"`, and everything after that closing quote — including a trailing comment —
  is discarded. So `SENDGRID_API_KEY="SG.xxx"` yields the key **without** the
  quotes, and `db_password="pa # ss"` keeps the spaces and the `#`. Quote any
  value that contains a space followed by a `#`, and remember that once a value
  is quoted a trailing comment on that line is no longer stripped — it is simply
  thrown away, which is what you want. A value with an opening quote and no
  closing quote is used exactly as written, quote included.
- **Blank lines** are skipped and are otherwise meaningless.
- **Lines without an `=`** are skipped silently.
- **Unknown keys are silently ignored.** Nothing is logged. A misspelled key
  looks exactly like a correct one, and you find out only when the feature you
  thought you configured behaves as if you had not.
- **Duplicate keys:** the last occurrence in the file wins. The one exception is
  `show_logon_stats`, which has its own reader and takes the *first* occurrence.

> **If you inherited a config file from somewhere else, still check the key
> names.** Case-insensitivity does not rescue a name whose *shape* is wrong.
> Sample and generated configs circulating for this BBS have used CamelCase names
> such as `Port`, `TLSPort`, `HttpdPort`, `FTPPort`, `FTPLimit`, `StartFTPD` and
> `SendgridAPIKey`. `Port` and `TLSPort` now work, because lowercasing them lands
> on real keys — but the rest do not, because the underscores are missing:
> `httpdport` is not `httpd_port` and `startftpd` is not `start_ftpd`. Those
> lines are ignored and the built-in default is used, with nothing logged. The
> names `ChatRefresh`, `NewsSearch`, `AlphavantageAPIKey` and `FinnhubAPIKey`
> turn up in the same files and are not options at all.

### All three readers follow the same rules

`tsu.cnf` is read by three different pieces of code — the main parser, the
remote-host reader and the `show_logon_stats` reader — and they used to disagree
about case, quotes and comments, which is how a trailing `# note` once ended up
inside a remote host's address. They now share one implementation, so everything
above applies everywhere in the file, `remoteN` lines included. You may quote and
comment any line.

One value is still handled specially: `required_conferences` is a comma-separated
list, so its quotes are stripped per item after the split rather than around the
whole line. Write it as `required_conferences="General","Support"`.

Because of that, **a `#` anywhere in the conference list truncates it**, quoting
or not: the trailing-comment rule is applied to the whole line before it is split
on commas, so `required_conferences="General","Off # Topic"` protects only
`General` and drops the rest. Conference names cannot contain a `#`. The setup
wizard refuses one.

### Value matching is case-insensitive

Boolean values accept all the spellings operators actually use, in any case:

| On | Off |
|---|---|
| `yes`, `true`, `1`, `on` | `no`, `false`, `0`, `off` |

There is one parser for all of them, so every on/off key behaves identically —
`start_sshd=false` disables SSH and `smtp_drop_dimarc=true` enables the drop,
both of which do what they look like they do.

**Anything else is refused, not guessed at.** `start_sshd=maybe` leaves SSH at
its built-in default and writes a warning to the console and to the BBS `LOG`
screen naming the key and the value. The same is true of numbers: `port=327O`
(letter O) keeps port 3270 *and tells you*, instead of leaving you to work out
why nobody can connect on the port you typed.

There is still no range validation when the file is parsed. `port=99999` is
accepted and then fails when the listener tries to bind — but that bind failure
is now reported too (see below). The first-run wizard validates 1-65535 up front;
a hand-edited file gets that check only at bind time.

### What counts as a fatal configuration error

The BBS refuses to start only if the configuration file cannot be **read at
all**. Exactly two things produce that:

1. **The file cannot be opened.** In practice you will not see this at startup,
   because a missing `tsu.cnf` triggers the interactive setup wizard first.
2. **The file cannot be read to the end** — an I/O error, or a single line longer
   than 1 MiB. No realistic `tsu.cnf` line approaches that.

**No value in the file can stop the BBS from starting.** A missing key, an
unparseable number, a nonsense boolean, an unknown key, a `bbs_name` that is too
long, a database that does not exist, a certificate path that does not exist —
all of these are reported and the BBS carries on with its built-in default.

This matters more than it sounds. The BBS is normally run under a supervisor
(`start_tsu.bash`'s restart loop, or systemd with `Restart=always`), and a
process that exits on a bad config file does not stop — it restarts forever,
usually with the reason scrolling past too fast to read. Refusing to boot over a
cosmetic setting was the worst possible response, so nothing does that any more.

`bbs_name` is the specific case worth knowing about: a name longer than 10
characters is **truncated to 10 and logged**, and the rest of the file is read
normally. It used to abort the parse on that line, which silently discarded every
key below it — and `bbs_name` sits near the top of the file, so that meant nearly
all of it.

Separately, a database initialisation failure is fatal, and failing to bind the
main TN3270 port is fatal. **Every other listener failure is now reported** — the
service name, the port and the reason go to the console in red and to the `LOG`
screen — but the BBS keeps running without that service.

---

## 2. Quick reference: every key

"Default" is the value in effect when the key is absent from the file.

### Identity and appearance

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `bbs_name` | Short BBS name; also the federation node identity | Optional | `Forum3270` |
| `MOTD` | Message of the day on the menus | Optional | empty (blank row) |
| `show_logon_stats` | Shows F2=About on the logon screen | Optional | `no` |
| `dns_name` | *(has no effect — see §10)* | Optional | empty |

### Network services and ports

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `port` | TN3270 listener port | Optional | `3270` |
| `tlsport` | TN3270-over-TLS listener port | Optional | `0` (no TLS) |
| `httpd_port` | Web interface, plaintext | Optional | `9000` |
| `https_port` | Web interface, TLS | Optional | `9443` |
| `ftp_port` | FTP control port | Optional | `2100` |
| `sshd_port` | SSH listener port | Optional | `2222` |
| `fingerd_port` | FINGER listener port | Optional | `79` |
| `smtp_port` | Inbound SMTP listener port | Optional | `2525` |
| `start_tls` | Start the TLS TN3270 listener | Optional | `no` (off) |
| `start_httpd` | Start the web interface | Optional | **on** |
| `start_ftpd` | Start the FTP server | Optional | **on** |
| `start_proxy3270` | Enable the remote-host menu | Optional | **on** |
| `start_sshd` | Start the SSH server | Optional | off |
| `start_fingerd` | Start the FINGER daemon | Optional | off |
| `start_smtpd` | Start the inbound SMTP server | Optional | off |
| `start_web3270` | Enable the browser 3270 client | Optional | off |
| `mail_listen_port` | *(has no effect — see §10)* | Optional | `0` |

### TLS

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `tlscert` | Path to certificate (.crt/.pem) | Optional | empty |
| `tlskey` | Path to private key (.key/.pem) | Optional | empty |

### Database

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `db` | `pg`, `postgres` or `postgresql` selects PostgreSQL; `sqlite` or `sqlite3` selects SQLite | Optional | `sqlite3` |
| `db_host` | PostgreSQL host | Optional | `localhost` when `db=pg` |
| `db_port` | PostgreSQL port | Optional | `5432` when `db=pg` |
| `db_user` | PostgreSQL role | Required **if** `db=pg` | empty |
| `db_password` | PostgreSQL password | Required **if** `db=pg` | empty |
| `db_name` | PostgreSQL database name | Required **if** `db=pg` | empty (fails) |

### Email and SMTP

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `SENDGRID_API_KEY` | Master switch for all outbound email | Optional | empty (all outbound email off) |
| `verify_newuser_email` | Require a 4-digit email code at registration | Optional | `no` |
| `notify_admin_new_accounts` | Email the admin on each new registration | Optional | `no` |
| `max_emails_per_day` | Cap on self-mailed PDFs per user per day | Optional | `0` = unlimited |
| `new_users_sendban` | Days a new account cannot send outbound mail | Optional | `14` |
| `smtp_domain` | Domain accepted inbound and used as From | Required **if** `start_smtpd=yes` | empty |
| `smtp_drop_dimarc` | Discard mail to the `dimarc` local part | Optional | **on** |

### Federated newsgroups

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `newsgroup_db_address` | Newsgroup PostgreSQL host | All five required together | empty |
| `newsgroup_db_port` | Newsgroup PostgreSQL port | All five required together | empty |
| `newsgroup_db_user` | Newsgroup PostgreSQL role | All five required together | empty |
| `newsgroup_db_password` | Newsgroup PostgreSQL password | All five required together | empty |
| `newsgroup_db_name` | Newsgroup database name | All five required together | empty |

### Federated chat

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `globalchat_db_address` | Global chat PostgreSQL host | All four required together | empty |
| `globalchat_db_port` | Global chat PostgreSQL port | All four required together | empty |
| `globalchat_db_user` | Global chat PostgreSQL role | All four required together | empty |
| `globalchat_db_password` | Global chat PostgreSQL password | All four required together | empty |
| `globalchat_pollrate` | *(has no effect — see §10)* | Optional | `0.0` |

### Remote hosts (PROXY3270)

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `remoteN` | Host name shown in the menu | Required per entry | no entry |
| `remoteN_addr` | Hostname or IP to dial | Required per entry | entry discarded |
| `remoteN_port` | TCP port to dial | Required per entry | entry discarded |
| `remoteN_description` | Description column in the menu | Optional per entry | blank column |

### Features and content

| Key | Purpose | Required | Default when absent |
|---|---|---|---|
| `required_conferences` | Conferences users may not unsubscribe from | Optional | none protected |
| `newsapikey` | newsapi.org key for the hidden `NEWS` command | Optional | empty (`NEWS` refuses) |
| `ftp_limit` | FTP upload cap in KB, enforced per note | Optional | `20` |
| `chatgpt_key` | *(not used by the BBS — see §10)* | Optional | ignored |

---

## 3. Identity and appearance

### `bbs_name`

Optional; defaults to `Forum3270`. **Maximum 10 characters.** A longer value is
truncated to the first 10 and a warning naming the value and the truncation goes
to the console and the `LOG` screen; the rest of the file is read normally. The
count is in characters, not bytes, so a ten-character name containing an umlaut
is accepted as the ten characters you see.

Treat this as more than a cosmetic label. It appears on the logon screen, both
menus, the SSH banner, the FTP banner, the FINGER response, PDF footers,
outbound mail From names, and every web page. More importantly it is your **node
identity on the federation**: federated chat posts are attributed as
`bbs_name:username`, and newsgroup articles are stored under it. Changing
`bbs_name` on a federated BBS orphans everything you posted under the old name;
it does not rename it.

Writing `bbs_name=` with an empty value passes validation and overrides the
default with the empty string. That is worse than omitting the key: it blanks
the name everywhere and it **disables newsgroups entirely**, because newsgroups
require a non-empty `bbs_name`. You will see
`Newsgroups: Disabled / missing: bbs_name` in the startup log.

### `MOTD`

Optional; empty by default. Shown centred on the main menu. **The config file
imposes no length limit** — the 60-character limit you may have seen belongs to
the in-BBS `MOTD` command, not to the config file.

The main menu is safe at any length: it hard-truncates to 79 characters. The
**extended menu is not**: it places the raw, untruncated string in the field, and
its centring gives up once the text reaches 79. An MOTD longer than 79 bytes
therefore spills over the function-key row on the extended menu. Keep it under 79
characters; under 60 is safer and matches what the in-BBS command will let an
admin set. Note also that centring measures bytes, so a multibyte MOTD is
mis-centred on the extended menu even when it fits.

Quote the value if it contains a `#`, or everything from the `#` onward is
discarded. The shipped file quotes it, and the setup wizard always writes it
quoted. Remember that once the value is quoted, a trailing `#` comment on that
line is no longer stripped — so do not add one.

The in-BBS `MOTD` command changes the message for all sessions immediately but
**writes only to memory**. It is not persisted; the next restart reverts to
whatever `tsu.cnf` says.

### `show_logon_stats`

Optional; `no` when absent. Accepts the usual on/off spellings.

Despite the name — and despite the setup wizard's help text claiming it
"displays system statistics on the login screen" — this key does **not** control
any statistics. The aggregate presence counter on the logon screen is drawn
unconditionally. What this key actually controls is whether the **F2=About**
function key is offered and whether PF2 opens the pre-login About screen. With it
off, the F2 label is blank and PF2 does nothing.

This key is read by its own scanner, but that scanner now shares the parsing
rules described in §1, so a trailing `# comment` and surrounding quotes are
handled here exactly as everywhere else. If the key appears twice, this reader
takes the **first** occurrence rather than the last.

It is also re-read from disk on every logon-screen paint, so it changes without a
restart — at the cost of three file opens per repaint per connection.

---

## 4. Network services and ports

### Port collisions

Every listener binds a bare port number on all interfaces. There is no collision
detection anywhere. These must all differ:

`port`, `tlsport`, `httpd_port`, `https_port`, `ftp_port`, `sshd_port`,
`fingerd_port`, `smtp_port`.

(`mail_listen_port` is in that family conceptually but binds nothing — see §10.)
The FTP server also reserves the passive data range **40000-40100**, which
nothing else may use.

**Every bind failure is reported.** The service name, the port and the reason go
to the console in red and to the `LOG` screen, where they appear as
`TSU <SERVICE> FAILED ON PORT <n>` followed by the reason:

| Service | LOG line on bind failure | Effect |
|---|---|---|
| TN3270 (`port`) | — | **Fatal.** The BBS exits. |
| HTTP (`httpd_port`) | `TSU HTTPD FAILED ON PORT n` | No web interface; the BBS runs. |
| HTTPS (`https_port`) | `TSU HTTPDS FAILED ON PORT n` | Plain HTTP continues. |
| FTP (`ftp_port`) | `TSU FTPD FAILED ON PORT n` | No FTP; the BBS runs. |
| SSH (`sshd_port`) | `TSU SSHD FAILED ON PORT n` | No SSH; the BBS runs. |
| FINGER (`fingerd_port`) | `TSU FINGERD FAILED ON PORT n` | No FINGER; the BBS runs. |
| SMTP (`smtp_port`) | `TSU SMTPD FAILED ON PORT n` | No inbound mail; the BBS runs. |
| TLS TN3270 (`tlsport`) | See §5. | |

If a service you enabled is not answering, search the `LOG` screen for its
daemon name — `FTPD`, `HTTPD`, `SSHD`, `FINGERD`, `SMTPD` — and look for a
`FAILED` line. The reason follows it on the next line. A port collision or a
privilege problem is the usual cause.

Ports below 1024 require root or `CAP_NET_BIND_SERVICE`. The built-in default for
`fingerd_port` is 79 and an `smtp_port` of 25 is common; both fail to bind as an
unprivileged user, and both now say so.

### `port`

Optional; `3270` when absent. This is the plaintext TN3270 listener and the only
one whose failure stops the BBS. It is also the port the browser client is
locked to.

### `start_httpd`, `httpd_port`, `https_port`

`start_httpd` defaults to **on**. Write `no`, `false`, `0` or `off` to turn it
off.

HTTPS is not a separate service switch. It starts as part of the HTTP server
whenever `tlscert` and `tlskey` are both set and both files exist. It is entirely
independent of `start_tls`, which governs only the TN3270 TLS listener. If the
certificate or key file is missing you get
`HTTPS certificate file … not found, skipping HTTPS server` and plain HTTP
continues to serve.

### `start_ftpd`, `ftp_port`, `ftp_limit`

`start_ftpd` defaults to **on**. FTP exists to move notes and personal files in
and out.

`ftp_limit` is the per-note upload cap in kilobytes and defaults to 20. It is
printed at startup as `FTP upload limit: N KB` and it is **enforced**: an upload
that would push a note past the limit is refused with
`552 note exceeds the N KB upload limit` and the note is not truncated or
partially stored. Raise the value if your users need to move larger notes.

**`ftp_limit=0` does not mean "no uploads".** Zero is read as "not configured"
and the 20 KB default is used instead. There is no way to switch uploads off with
this key — turn FTP off with `start_ftpd=no` if that is what you want. The setup
wizard refuses a zero here for the same reason.

One caveat on how the refusal lands. A large file arrives in several chunks and
each is saved as it lands, so when the chunk that would cross the limit is
refused, the chunks that already fit are stored. The transfer fails and the
client is told, but the note keeps what got through — check and delete it rather
than assuming a refused upload left nothing behind.

The limit is re-read when FTP is restarted from SDSF (`P FTPD` then `S FTPD`), so
you can change it without a full BBS restart.

### `start_sshd`, `sshd_port`

Off when the key is absent. Defaults to port 2222.

The SSH host key is **not** configurable. It is loaded from, or generated into,
`ssh_host_key.pem` in the working directory. If that file cannot be read or
created, the SSH server does not start and says so on the console and the `LOG`
screen.

### `start_fingerd`, `fingerd_port`

Off by default. Default port 79, which needs root. A
FINGER query with no user name returns a system summary that includes `bbs_name`
and BBS uptime.

### `start_web3270`

Off by default. Serves a browser-based 3270 client.

**It requires `start_httpd` to be on.** The `/web3270` routes exist only inside
the web server, which only runs when HTTPD is enabled. With `start_web3270=yes`
and `start_httpd=no` the admin System screen will report web3270 as STARTED while
nothing serves the page, and nothing is logged to say so. It also needs
`./static/web3270/index.html` on disk, or the page returns HTTP 500.

Sessions are capped at 50 total and 5 per IP, and the client is locked to
`localhost` plus this BBS's own `port` so it cannot be used as an open proxy.

The inverse case is handled cleanly: HTTPD on with web3270 off returns HTTP 503
`web3270 service is not running`.

### `start_proxy3270`

Defaults to **on**. This is not a network listener and
has no port. It is a switch that gates the "remote host" menu. With it off, users
selecting the remote-host option get `PROX3270 disabled`. See §9 for the host
definitions themselves.

### `start_smtpd`, `smtp_port`, `smtp_domain`, `smtp_drop_dimarc`

See §7.

---

## 5. TLS

Three keys work together: `start_tls`, `tlsport`, and the pair
`tlscert`/`tlskey`.

`start_tls` is off by default. When it is on, the
TN3270 TLS listener starts **only if all three of `tlsport > 0`, `tlscert` and
`tlskey` are non-empty**. If any is missing you get a yellow warning naming
exactly which:

```
Warning: TLS server not started - missing configuration (port: 0, cert: , key: )
```

If the paths are set but a file does not exist, you get
`TLS certificate file … not found` or `TLS key file … not found` and the service
is marked ERROR on the admin System screen. In neither case does the BBS fail to
start — you simply have no TLS.

**`tlscert` and `tlskey` do double duty.** They are also what enables HTTPS on the
web interface, and that path does not consult `start_tls` at all. So:

- `tlscert` + `tlskey` set, `start_tls=no` → **HTTPS is on, TN3270-TLS is off.**
  This surprises people who read `start_tls=no` as "no TLS anywhere".
- `start_tls=yes` but no `tlscert`/`tlskey` → neither TLS listener starts.

There is no way to give the web interface a different certificate from the
TN3270 TLS listener.

Note also that no PostgreSQL connection the BBS makes uses TLS: the main
database and both federation databases always connect with SSL disabled, and no
key in `tsu.cnf` changes that (see §6 and §8).

---

## 6. Database

### `db`

Optional; `sqlite3` when absent. Four spellings are accepted, in any case:

| Value | Selects |
|---|---|
| `pg`, `postgres`, `postgresql` | PostgreSQL |
| `sqlite`, `sqlite3` | SQLite |

**Anything else is refused.** A typo leaves the database type at its previous
value and writes a red warning to the console and the `LOG` screen naming the
value you wrote. This used to be the highest-risk misconfiguration in the file:
only the exact string `pg` selected PostgreSQL, so `db=postgres` silently opened
the local `tsu.db` while a complete and correct set of `db_host` / `db_user` /
`db_password` / `db_name` credentials sat unused right below it.

Writing `db=` with an empty value is treated like an absent key and leaves the
default in place.

### SQLite (the default)

The filename is **hardcoded** as `tsu.db` relative to the working directory. It
is not configurable. On this path `db_user`, `db_password`, `db_host`, `db_port`
and `db_name` are read and then completely ignored.

The file must already exist. If it does not, the BBS reports
`database 'tsu.db' not found - application cannot start without an existing
database`. In normal operation you will not reach that, because a missing
`tsu.db` triggers the setup wizard first.

WAL journal mode and a 4096-byte page size are applied at startup; failures there
are warnings only.

### PostgreSQL (`db=pg`)

The connection string is assembled as:

```
host=… port=… user=… password=… dbname=… sslmode=disable
```

Five things follow from that:

- **An absent or empty `db_port` becomes 5432, and an absent or empty `db_host`
  becomes `localhost`.** These are filled in after the file is read, so the
  connection string never carries an empty `port=` — which used to override the
  driver's own default and produce a connection failure instead of the obvious
  5432. Setting both explicitly is still clearer.
- **An empty `db_name`** makes PostgreSQL fall back to a database named after the
  connecting role, which normally does not exist:
  `FATAL: database "<user>" does not exist`.
- **SSL is disabled and cannot be changed from `tsu.cnf`.** The password and all
  query traffic cross the network in the clear. A remote `db_host` needs a tunnel
  or a private network.
- There is **no connection timeout**, so a host that drops packets rather than
  refusing them will hang the BBS at startup rather than failing fast.
- **A PostgreSQL failure at startup is fatal.** The BBS prints the error, adds
  `Please ensure the PostgreSQL database is accessible with the provided
  credentials.` and exits before binding any listener. This is the opposite of
  the SQLite integrity check, which is deliberately non-fatal.

### A trap for PostgreSQL installations

The first-run check looks for `tsu.cnf` **or `tsu.db`** and never consults `db=`.
On a PostgreSQL installation there is legitimately no `tsu.db`, so a fresh
install will drop into the wizard's database-creation screen and, on F10, create
a SQLite `tsu.db` that the BBS then never uses. It is harmless but confusing.
Keeping an empty `tsu.db` file present suppresses it.

---

## 7. Email and SMTP

### `SENDGRID_API_KEY` — the master switch for outbound mail

Optional; empty when absent. Surrounding quotes **are** stripped, so the shipped
form `SENDGRID_API_KEY="SG.xxx"` yields the bare key.

With it empty, every outbound-mail feature degrades softly and individually.
Nothing crashes and nothing is fatal, but the surfaces differ:

- Mailing a note, topic, message or held output as a PDF returns
  `Email functionality not configured`.
- The BASIC and assembler environments print
  `?EMAIL FUNCTIONALITY NOT CONFIGURED`.
- Composing to an external address appends
  `SendGrid not configured for external emails` to the per-recipient error list;
  internal BBS recipients in the same compose are still delivered.
- Changing your email address in the profile **skips verification and saves the
  new address directly**.
- The newsgroup digest sender never starts, with no log line either way.
- Inbound mail forwarding via a `.FORWARD` note is dropped with
  `FORWARD: no SendGrid API key configured`, though the message is still
  delivered to the local mailbox.
- The F2=Forward key and the newsgroup email-delivery settings row simply do not
  render.

One hardcoded detail you cannot configure: the From address on **registration
verification emails** is `noreply@moshix.tech`, and the same address is used for
newsgroup digests. It does not use `smtp_domain`. If you are not the upstream
author, verification mail will be sent from a domain you do not own, which most
receiving mail systems will treat accordingly. This is not something `tsu.cnf`
can fix.

### `verify_newuser_email`

Optional; `no` when absent.

**Prerequisite: it needs `SENDGRID_API_KEY` as well.** If you set
`verify_newuser_email=yes` and leave the SendGrid key empty, **registration
completes with no verification at all** — new users go straight through to the
timezone screen.

Startup now says so, in red, on the console and on the `LOG` screen:

```
Cannot verify new users: no SendGrid key in tsu.cnf
```

Take that line seriously; it means new accounts are being created unchecked
while your configuration says otherwise. It used to happen with nothing said at
all. The first-run wizard additionally forces this key to `no` when no SendGrid
key is present.

When both are set, registration sends a 4-digit code and holds the user on a
verification screen. If the send **fails** (bad key, SendGrid rejects it), the
user is bounced back to the register screen with
`Failed to send verification email` and **the account is not created** —
registration is a dead end until you fix the key. Code entry itself has no
attempt limit and the code does not rotate on a wrong guess.

### `notify_admin_new_accounts`

Optional; `no` when absent. Sends the admin an email when a new user first
reaches the main menu (not at registration).

It has **four** preconditions: the session must be newly registered, this key
must be on, `SENDGRID_API_KEY` must be non-empty, and — the silent one — the
admin account must have an email address on file. If it does not, nothing is sent
and **nothing is logged**. If you have this on and see no notifications, check the
admin user's email address before anything else.

### `max_emails_per_day`

Optional; **`0` when absent, and `0` means unlimited.** It does not mean "block
everything". Administrators are exempt unconditionally. A negative or
non-numeric value is refused with a warning and the previous value is kept.

Two limitations worth knowing:

- The counter is **in-memory only** and resets on date rollover *and on every BBS
  restart*. A restart clears everyone's quota.
- It only governs the **mail-a-PDF-to-yourself** paths. The external-email
  compose paths neither check nor increment it. So `max_emails_per_day=4` does
  **not** cap how much mail a user sends to arbitrary internet addresses; it caps
  PDF exports.

### `new_users_sendban`

Optional; **`14` when absent**. Number of days a newly registered non-admin
account is blocked from sending outbound mail or emailing PDFs.

`0` — and any negative number, which is accepted without complaint —
**disables** the feature. It also fails open for administrators and for any user
whose registration date is unset, which includes all older accounts and the seed
accounts.

The effective value is printed at startup regardless
(`NEW USERS EMAIL BLOCK 14 DAYS`), so you always get one line confirming it. When
it blocks something, the user sees the deliberately opaque string
`INFO14D GENERAL ERROR` rather than an explanation.

### `start_smtpd`, `smtp_port`, `smtp_domain`

`start_smtpd` is off by default. `smtp_port` defaults to **2525** specifically so
it does not need root; setting it to 25 needs root or
`CAP_NET_BIND_SERVICE`.

**`smtp_domain` is a hard prerequisite.** With `start_smtpd=yes` and an empty
`smtp_domain`, the server refuses to start before binding anything and says
`SMTP server not started - no smtp_domain configured`. A bare TLD is also
rejected; the check is crude — it just requires at least one dot.

These settings can be changed without restarting the BBS: `P SMTPD` then
`S SMTPD` from the SDSF Activity screen re-reads `tsu.cnf` and rebinds.

Two details of that command are worth knowing. If the configuration is
unusable — no `smtp_domain`, or a bare TLD — the SDSF error row shows the reason
rather than reporting success. And if you forget the `P SMTPD` first, it answers
`SMTP server already running - P SMTPD first` instead of silently doing nothing
while you believe your edit was applied. On success it says
`SMTP server starting`, not "started": the bind happens a moment later, so the
result — including a `TSU SMTPD FAILED ON PORT n` line — appears on the `LOG`
screen.

Once running, `smtp_domain` is what decides which mail is accepted. Anything
addressed outside the domain (or its subdomains) gets `550 Relay not permitted`.
The matcher reduces `www.example.com` to `example.com` and then accepts that plus
all subdomains. Recipients are accepted even when the local user does not exist.

`smtp_domain` is **also** the From domain for outbound SendGrid mail, and that
matters even with SMTPD switched off. Replying to and bulk-sending external mail
return `SMTP domain not configured` when it is empty, and forwarding has no guard
at all — it builds a malformed `user@` sender that SendGrid rejects with an
opaque `SendGrid error 400`. If you use outbound external email at all, set
`smtp_domain` whether or not you run the SMTP listener.

### `smtp_drop_dimarc`

Optional; **on by default**. `yes`, `true`, `1` and `on` all keep it on, and
`no`, `false`, `0` and `off` all turn it off.

Also: despite the wizard labelling it "Drop DMARC Emails", the local part it
actually matches is the literal string **`dimarc`**, not `dmarc`. Mail to
`dmarc@yourdomain` is not dropped. Dropping is silent to the sender — the session
still gets a `250` — and appears only as `SMTP: drop dimarc from …` in the log.

---

## 8. Federation: newsgroups and global chat

Both subsystems point at a **separate** PostgreSQL server, unrelated to `db=pg`.
Both connect with SSL disabled, so both send their password and all their traffic
in the clear.

### Newsgroups — five keys, all required together

`newsgroup_db_address`, `newsgroup_db_port`, `newsgroup_db_user`,
`newsgroup_db_password`, `newsgroup_db_name`. All five must be non-empty **and**
`bbs_name` must be non-empty, or the feature is disabled.

This has by far the best diagnostics in the file. When something is missing you
get an explicit list at startup:

```
Newsgroups: Disabled
  missing: newsgroup_db_password, newsgroup_db_name
```

On a connection failure you get `Newsgroups: FAILED (host:port) - <error>` in red
and the BBS carries on. There is **no retry**: the connection is attempted once at
startup, so a newsgroup database that comes up after the BBS requires a BBS
restart. There is no connection timeout either, so an unreachable host stalls
startup for the OS TCP timeout.

With newsgroups disabled, the feature screen says
`Newsgroups feature is not available`, the hourly digest loop skips, and `bbs://`
links to groups or articles resolve to unavailable.

### Global chat — four keys, all required together

`globalchat_db_address`, `globalchat_db_port`, `globalchat_db_user`,
`globalchat_db_password`. All four must be non-empty or the startup smoke test is
skipped entirely, **with no log line at all** — unlike newsgroups, there is no
"missing key" diagnostic here. On success you get
`GlobalChat: Connected (host:port)`; on failure, red `GlobalChat: FAILED`, and
the BBS carries on.

**There is no `globalchat_db_name` key, and that is deliberate.** The database
name is hardcoded to `globalchat`. The remote server must have a database with
exactly that name, containing a `chat` table. If it does not, you get
`FATAL: database "globalchat" does not exist` and there is no configuration knob
that will help.

The most likely visible symptom of a *bad* global chat host is not an error
message but latency: the federated active-user count opens a fresh connection on
every paint of the logon screen, the main menu and the extended menu, swallowing
all errors and returning 0. The connection timeout is 3 seconds, so a host that
blackholes packets adds **up to three seconds to every menu render**. If your
menus feel slow, check these four keys first.

Two further caveats, stated so you do not chase them:

- **The federated chat screen is currently unreachable from the UI.** Both entry
  points report `Federated chat is disabled`. Today the four keys affect only the
  startup log line and the federated user-count number on the menus.
- The newsgroups screen is reachable, but only through the `=G` shortcut. The
  extended-menu `G` option and the `M;G` shortcut always report
  `Newsgroups is disabled` regardless of configuration.

---

## 9. Remote hosts (`remoteN`)

These define the entries in the PROXY3270 "Remote Host Selection" menu. They are
read by their own reader, which now follows exactly the same syntax rules as the
rest of the file (see §1).

A host is a block of up to four lines:

```
remote1=MVS3.8
remote1_description="MVS 3.8 TK5 community mainframe"
remote1_addr=localhost
remote1_port=1111
```

**Rules:**

- **Numbering does not have to be contiguous, and does not have to be in order.**
  The shipped file has 1-7, 9, and 11-13 — no `remote8`, no `remote10` — and that
  is fine. A new host block starts at any key that begins with `remote` and
  contains no underscore; the digits are just a label used to associate the
  sub-keys. A gap does not truncate the list.
- **The number is not the menu number.** Menu options are numbered 1..N by
  position in the file, and selection is by that position. So the shipped
  `remote11` is menu option 8. Reordering the blocks in the file reorders the
  menu.
- **There is no limit on how many hosts are parsed**, but the menu displays at
  most 15 on a 24x80 screen, 24 on 32x80, and 35 on 43x80. Beyond that you get a
  yellow `(Showing 15 of 20 hosts)` note — but selection is validated against the
  *full* list, so an option number you cannot see still works if you type it.
- **`remoteN`, `remoteN_addr` and `remoteN_port` are all required.** A block
  missing any of the three is **silently discarded**. `remoteN_description` is
  optional; without it the description column is blank.
- **Order within a block matters.** The sub-keys must come *after* their
  `remoteN=` line. A `remote2_addr` written above `remote2=` is either ignored
  or, worse, silently attributed to the previous host.
- **Comments and quotes work on every line of the block.**
  `remote1_port=1111 # main` gives the port `1111`, and
  `remote1_addr="host.example.com"` gives the bare address. This was not always
  so — this reader used to strip neither, on any key except `_description`, so a
  quoted address or a trailing note produced a dial failure with no explanation.
  If you inherited a file written to work around that, it still works.
- The port is kept as a **string** and handed straight to the dialler, so a
  non-numeric value produces a dial error at connect time, not a config error at
  startup.

If no valid host parses, the menu reports
`No remote hosts configured in tsu.cnf`. If `start_proxy3270=no`, the menu
reports `PROX3270 disabled` before it even looks at the file.

Because the file is re-read on every menu paint, **remote host edits are live —
no restart needed.**

---

## 10. Dead and unused keys

These keys are accepted — some of them are validated, offered by the setup
wizard, and present in the shipped file — but they have **no effect on the
running system**. An operator setting one reasonably expects something to happen,
and nothing does. This section exists because that is worth knowing.

| Key | Status |
|---|---|
| `dns_name` | **Accepted, never used.** Nothing consults it — not `bbs://` link resolution, not email routing, despite the wizard's help text saying otherwise. The wizard nonetheless makes it **mandatory**, so a fresh install is forced to supply a value the BBS then ignores. |
| `mail_listen_port` | **Accepted, never used.** No listener is ever bound on it. Absent or present, nothing is attempted and nothing is logged. It is not in the shipped file and not offered by the wizard. Treat it as reserved but unimplemented. |
| `globalchat_pollrate` | **Accepted, never used.** Values of `0` or less are discarded outright, and any other value is stored and then never consulted. The "0 = use adaptive algorithm" wording is misleading: the poll cadence is a fixed 3 seconds regardless of what you write here. |
| `chatgpt_key` | **Not used by the BBS.** It appears in the shipped `tsu.cnf`, and the BBS ignores it completely. Leaving it in place is harmless; removing it changes nothing. |

Two more that are not `tsu.cnf` keys at all but which you may encounter and
should not copy:

- `ChatRefresh`, `NewsSearch` and `AlphavantageAPIKey` appear in some generated
  and sample config files. They are not options; nothing reads them.
- `discord_token`, `discord_guild_id`, `show_discord_in_menu` — present in
  `tsu.gcloudPostgres.cnf` in this directory. There is no Discord support in the
  BBS. If you start from that file as a template, these three lines do nothing.

---

## 11. Secrets

`tsu.cnf` stores several credentials **in cleartext**. There is no encryption, no
keyring integration, and no support for reading them from environment variables
or from a separate file.

The keys that are secrets:

| Key | Secret |
|---|---|
| `SENDGRID_API_KEY` | SendGrid API key |
| `newsapikey` | newsapi.org API key |
| `db_password` | Main PostgreSQL password |
| `globalchat_db_password` | Federated chat PostgreSQL password |
| `newsgroup_db_password` | Federated newsgroups PostgreSQL password |
| `tlskey` | Path to the TLS private key — the file it names is itself a secret |
| `chatgpt_key` | An API key value; not used by the BBS, but still a secret if present |

Practical points:

- **The copy of `tsu.cnf` in this working directory contains live-looking
  values**, and so do `tsu.gcloudPostgres.cnf` and `tsu.backup.cnf` beside it.
  If any of them is the one you deployed from, rotate the credentials.
- **Nothing validates a key, only that it is non-empty.** A revoked, expired,
  truncated or malformed SendGrid or newsapi.org key looks exactly like a good
  one at startup — you get no warning and no log line. The failure appears the
  first time the key is used: a registration that dead-ends on
  `Failed to send verification email`, an outbound mail that fails with an opaque
  `SendGrid error 400`, or a `NEWS` command that returns nothing. After rotating
  a key, send one test message rather than trusting a clean startup.
- **File permissions.** The setup wizard writes `tsu.cnf` world-readable (mode
  `0644`). Every local user on the host can then read every credential.
  `chmod 600 tsu.cnf` and make it owned by the account the BBS runs as. Nothing
  depends on it being readable by anyone else.
- **Version control.** `.gitignore` in this repository already covers `*.cnf` and
  `tsu.cnf` explicitly, and `tsu.cnf` is untracked, so the shipped file is not
  committed. Keep it that way. If you fork this repository, verify that
  `.gitignore` survived before your first commit, and never commit a config with
  real values — even to a private repository, and even briefly, since rotating is
  the only remedy once a key has been pushed.
- **The database passwords cross the network unencrypted.** All three PostgreSQL
  connections disable SSL and this cannot be changed from `tsu.cnf`. If any of
  those databases is not on localhost or a private network, tunnel the
  connection.
- **Backups and support requests.** Because these are inline values rather than
  file references, anything that copies `tsu.cnf` — a backup, a paste into an
  issue, a container image layer — copies the secrets with it. Redact before
  sharing.

---

## 12. Checklist of surprises

Collected in one place, because each of these has bitten someone:

1. **Misspelled keys are ignored in silence.** Nothing warns about an unknown
   key, so a typo looks exactly like a correct line and the feature simply
   behaves as if you never configured it. Check spelling first when a setting
   appears to do nothing.
2. **`verify_newuser_email=yes` without a SendGrid key does not verify anyone.**
   Registration proceeds unverified. Startup now says so in red, on the console
   and on the `LOG` screen — but the accounts are still unverified.
3. **`max_emails_per_day=0` means unlimited**, not zero. It also caps only
   mailing PDFs to yourself, not mail sent to external addresses.
4. **`tlscert`/`tlskey` enable HTTPS even with `start_tls=no`.** `start_tls`
   governs only the TN3270 TLS listener; the web server picks the certificate up
   on its own.
5. **`start_web3270=yes` needs `start_httpd=yes`.** Otherwise the System screen
   reports web3270 as STARTED while nothing serves the page.
6. **`bbs_name=` with an empty value disables newsgroups**, and blanks the name
   on every screen. Omitting the key entirely is safer than emptying it.
7. **The `remoteN` digit is not the menu number.** Menu options are numbered by
   position in the file, so `remote11` may well be option 8.
8. **A `#` only starts a comment at the start of a value or after a space.**
   `pa#ss` is a whole password; `pa #ss` is `pa`. Quote anything with a space
   before a `#`, and put no trailing comment on a quoted line.
9. **There is no range checking on ports when the file is read.**
   `port=99999` is accepted and fails at bind time — reported, but at bind time.
10. **`ftp_limit=0` means 20 KB, not "no uploads".** Zero reads as "not
    configured" and the default is used.
11. **A `#` truncates `required_conferences` even when the names are quoted**,
    because the comment is stripped from the whole line before the commas are
    split. Conference names cannot contain a `#`.
12. **`S SMTPD` starts SMTPD even when `start_smtpd=no`.** An explicit operator
    command wins over the file; the file decides only what happens at the next
    startup. The same is true of `S FTPD` and `S FINGERD`.
13. **CamelCase key names still do not work.** Keys match in any case, but not
    with the underscores missing: `HttpdPort` is not `httpd_port`.
14. **`dns_name`, `mail_listen_port` and `globalchat_pollrate` do nothing**, and
    `chatgpt_key` is not used by the BBS.

### What used to be on this list

If you are working from an older copy of this document, or from an inherited
config file written to work around these, they are all fixed:

- Keys were case-sensitive, so `START_FINGERD` and `start_ftpd` were ignored.
- `start_SSHD=false` turned SSH **on** and `smtp_drop_dimarc=true` turned the
  drop **off**, because two incompatible boolean styles were in use.
- `db=postgres` silently used SQLite.
- An empty `db_port` was a connection failure rather than 5432.
- Unparseable numbers were discarded in silence.
- HTTP, SSH and FINGER bind failures were silent.
- `show_logon_stats` did not strip inline comments.
- `remoteN_addr` and `remoteN_port` accepted neither quotes nor comments.
- A `bbs_name` over 10 characters aborted the parse, discarding every key below
  it, and refused to boot.
- `ftp_limit` was advertised but never enforced.
- `S SMTPD` did not re-read the file.
- `finnhub_API_key` was read and never used; it is no longer read at all.

---

## 13. Example configurations

### The smallest thing that works

Every key is optional, so the smallest working `tsu.cnf` is literally an empty
file: the BBS starts on SQLite (`tsu.db` must already exist), listens for TN3270
on 3270, serves HTTP on 9000, runs FTP on 2100, enables the remote-host menu, and
calls itself `Forum3270`.

The smallest configuration worth actually writing:

```ini
# Identity
bbs_name=MyBBS

# TN3270
port=3270

# Web interface (on by default; named here so the port is explicit)
httpd_port=9000

# Everything else off
start_ftpd=no
start_proxy3270=no
start_tls=no
```

Note that `start_ftpd` and `start_proxy3270` must be turned off *explicitly* —
they default to on.

### A full `tsu.cnf`

This is a complete, working file. Copy it, replace the placeholders, and
uncomment the blocks you actually want. Key names are written lowercase and
booleans as `yes` or `no`; both are conventions rather than requirements, since
keys match in any case and `true`/`1`/`on` and `false`/`0`/`off` work too. The
two uppercase keys are spelled that way because some of the shipped shell
scripts look for them literally.

```ini
# ═══ Identity ═══════════════════════════════════════════════════════════════
# bbs_name: max 10 characters. Longer is truncated to 10, with a warning.
# It is also your node name on the federation - changing it orphans your
# federated posts rather than renaming them. Never leave it empty: an empty
# value blanks the name everywhere and disables newsgroups.
bbs_name=MyBBS

# MOTD: keep under 60 characters. Quoted because it may contain a '#'; note
# that a quoted value does NOT get trailing comments stripped, so never put a
# comment after this line.
MOTD="Welcome to MyBBS - mail is yourUserID@example.com"

# show_logon_stats: enables F2=About on the logon screen (it does NOT show
# statistics, despite the name). Re-read on every logon-screen paint.
show_logon_stats=yes

# dns_name is accepted but has no effect anywhere. Left here because the
# first-run wizard insists on it.
#dns_name=bbs.example.com

# ═══ Database ═══════════════════════════════════════════════════════════════
# Accepted: sqlite, sqlite3, pg, postgres, postgresql. Anything else is
# refused with a red warning and the previous value is kept.
db=sqlite3
# SQLite uses the hardcoded file tsu.db in the working directory; it must
# already exist, and the db_* keys below are ignored on this path.

# For PostgreSQL, set db=pg and uncomment what you need. db_host defaults to
# localhost and db_port to 5432 when they are absent or empty.
# The connection always has SSL disabled - tunnel it if the host is remote.
# A PostgreSQL failure at startup is fatal; the BBS will not start.
#db=pg
#db_host=db.internal.example.com
#db_port=5432
#db_user=bbs
#db_password="CHANGE_ME"
#db_name=tsu

# ═══ TN3270 ═════════════════════════════════════════════════════════════════
# The only listener whose bind failure stops the BBS. Every other bind failure
# is reported on the console and the LOG screen, and the BBS carries on.
port=3270

# TLS TN3270 needs ALL of start_tls=yes, tlsport>0, tlscert and tlskey, and
# both files must exist. Uncomment all four together.
start_tls=no
#start_tls=yes
#tlsport=2023
#tlscert=/etc/ssl/certs/bbs.example.com.crt
#tlskey=/etc/ssl/private/bbs.example.com.key

# ═══ Web ════════════════════════════════════════════════════════════════════
# start_httpd defaults to ON.
start_httpd=yes
httpd_port=9000
https_port=9443
# HTTPS starts automatically whenever tlscert and tlskey above are set and the
# files exist. It ignores start_tls entirely.
# "P HTTPD" then "S HTTPD" from SDSF re-reads this file and rebinds.

# start_web3270 needs start_httpd=yes, or it reports STARTED while serving
# nothing. It also needs ./static/web3270/index.html on disk.
start_web3270=yes

# ═══ Other services ═════════════════════════════════════════════════════════
# start_ftpd defaults to ON. FTP also reserves the passive range 40000-40100.
# ftp_limit is the per-note upload cap in KB and IS enforced: a larger upload
# is refused with "552 note exceeds the N KB upload limit". 0 is NOT "no
# uploads" - it reads as "not configured" and gives you the 20 KB default.
# "P FTPD" then "S FTPD" re-reads this file, ftp_limit included.
start_ftpd=yes
ftp_port=2100
ftp_limit=40

# The SSH host key is not configurable; it lives in ./ssh_host_key.pem.
start_sshd=yes
sshd_port=2222

# FINGER: default port 79 needs root, so use a high port unless you have it.
# "S FINGERD" re-reads this file.
start_fingerd=yes
fingerd_port=1079

# The remote-host menu (see the Remote hosts section at the bottom).
# Defaults to ON.
start_proxy3270=yes

# ═══ Email ══════════════════════════════════════════════════════════════════
# Outbound email needs SENDGRID_API_KEY, set in the Secrets block at the end.
# With no key, all of the settings below degrade softly and individually.

# verify_newuser_email=yes with an empty SendGrid key means new accounts are
# created with NO verification. Startup warns in red when that happens, but
# leave this "no" until the key below is real and tested.
verify_newuser_email=no

# Also needs a SendGrid key AND an email address on the admin account, or it
# silently sends nothing.
notify_admin_new_accounts=yes

# 0 means UNLIMITED, not zero. Caps mailing PDFs to yourself only - it does
# not limit mail sent to external addresses. Resets on every BBS restart.
max_emails_per_day=4

# Days a new non-admin account cannot send mail or PDFs. 0 disables.
new_users_sendban=14

# Also the From domain for ALL outbound mail, even with SMTPD off.
# Set it if you send external mail at all. A bare TLD is rejected.
smtp_domain=example.com

# ═══ Inbound SMTP ═══════════════════════════════════════════════════════════
# Requires a non-empty smtp_domain above or it refuses to start and says why.
# "P SMTPD" then "S SMTPD" from SDSF re-reads this file, so smtp_port and
# smtp_domain can be changed without a full restart.
start_smtpd=yes
smtp_port=2525                # port 25 needs root

# Drops mail to the local part "dimarc" (not "dmarc"). On by default.
smtp_drop_dimarc=yes

# ═══ Content ════════════════════════════════════════════════════════════════
# Conferences users may not unsubscribe from. Re-read live - edits take effect
# without a restart. No trailing comment on this line, and no '#' inside a
# conference name: both truncate the whole list.
required_conferences="General","3270BBS","User content"

# ═══ Federated newsgroups ═══════════════════════════════════════════════════
# All five keys AND a non-empty bbs_name are required, or the feature is off
# and startup tells you exactly which keys are missing.
# Connected once at startup with no retry and no timeout; SSL is disabled.
#newsgroup_db_address=federation.example.com
#newsgroup_db_port=5432
#newsgroup_db_user=bbs
#newsgroup_db_password="CHANGE_ME"
#newsgroup_db_name=newsgroups

# ═══ Federated chat ═════════════════════════════════════════════════════════
# All four are required together, and a bad host silently adds up to 3 seconds
# to EVERY menu paint. There is no globalchat_db_name key: the remote database
# must be named exactly "globalchat".
#globalchat_db_address=federation.example.com
#globalchat_db_port=5432
#globalchat_db_user=bbs
#globalchat_db_password="CHANGE_ME"
# globalchat_pollrate is accepted but has no effect; polling is fixed at 3s.
#globalchat_pollrate=1

# ═══ Remote hosts ═══════════════════════════════════════════════════════════
# Re-read on every menu paint, so edits here are live - no restart needed.
# Numbering may have gaps and need not be ordered; the MENU number is the
# block's position in this file, not the digit in the key.
# Each block needs remoteN, remoteN_addr and remoteN_port or it is silently
# discarded, and the sub-keys must follow their remoteN= line.
remote1=MVS3.8
remote1_description="MVS 3.8 TK5 community mainframe"
remote1_addr=localhost
remote1_port=1111

remote2=PUBVM
remote2_description="VM/SP rel5 with PROFS"
remote2_addr=pubvm.org
remote2_port=24

# ═══ Secrets ════════════════════════════════════════════════════════════════
# Cleartext. chmod 600 this file and never commit it.
# Nothing checks that a key is valid, only that it is non-empty - a revoked or
# malformed key looks perfectly fine at startup and fails on first use.
# Quote any secret that contains a space followed by a '#', and add no trailing
# comment to a quoted line.

# Master switch for ALL outbound email. Empty or absent = no outbound mail.
#SENDGRID_API_KEY="SG.REPLACE_WITH_YOUR_KEY"

# newsapi.org key for the hidden NEWS command. Without it, NEWS refuses.
#newsapikey=REPLACE_WITH_YOUR_KEY

# chatgpt_key appears in the shipped file but is not used by the BBS.
#chatgpt_key=REPLACE_WITH_YOUR_KEY
```
