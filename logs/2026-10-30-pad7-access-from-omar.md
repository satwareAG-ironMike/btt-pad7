# 2026-10-30 - pad7 access from omar, ssh alias for the pad on mw

| Field | Value |
|-------|-------|
| what | (a) `mw:~/.ssh/config`: `Host bttpad7` -> `Host btt-pad7 bttpad7` plus `IdentityFile ~/.ssh/id_ed25519`, `IdentitiesOnly yes`, `ConnectTimeout 10`, `ServerAliveInterval 60`, `ServerAliveCountMax 3`. (b) `omar:~/.ssh/config` (new file, 0600): `Host *` ControlMaster/ControlPath/ControlPersist 600 block and `Host btt-pad7 bttpad7` block -> `HostName 192.168.178.107`, `User b0t`, `IdentityFile ~/.ssh/id_ed25519_btt-pad7`, `IdentitiesOnly yes`. (c) `omar:~/.ssh/known_hosts`: 3 pad host-key lines (ed25519, rsa, ecdsa) copied from `mw:~/.ssh/known_hosts` - pinned, no TOFU. (d) CB1 state change: appended omar's public key to `/home/b0t/.ssh/authorized_keys` on 192.168.178.107 (append only, line count 1 -> 2; original line 1 `mw@cachyos-homeoffice` `SHA256:rzB/zXh5E4JBiUNouddl7pHYtR6yfGkXrEBXRJCRq8I` untouched; `.ssh` 700, `authorized_keys` 600) |
| where | `mw` (this workstation), `omar` (192.168.178.105), `BTT-Pad7` (192.168.178.107) |
| when | 2026-10-30 20:55-21:00 (local) |
| why | user request: make the `btt-pad7` spelling work on mw and let `ssh omar` reach the pad. Pre-fix failure mode on mw: `ssh btt-pad7` and `ssh btt-pad7.fritz.box` both rc 255 `Host key verification failed.` - no Host block matched, default user `mw`, name absent from `known_hosts`; `btt-pad7.fritz.box` also maps to 192.168.178.133, which is not the pad |
| result | verified live: `ssh btt-pad7` on mw rc 0 -> `BTT-Pad7`, user `b0t`; `ssh bttpad7` on mw rc 0; from omar: `ssh btt-pad7` rc 0 -> `BTT-Pad7`, `b0t`, kernel `7.0.2-vendor-sunxi64`, `nproc` 4; omar ping .107 0% loss. Key enrolled: `~/.ssh/id_ed25519_btt-pad7` on omar, public pin `SHA256:HMpTWVChsTqBFqc1GtR7F3OJfHZFD94W8/3kPgQE1BA`, exception registered in `/home/omar/.ssh/exceptions.md` (reason: headless agent host, no FIDO token; review date 2027-01-30) |

Redaction (constitution VI): private key material not recorded here; public pins only. No token or key value transferred out of the hosts.
