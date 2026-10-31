# 2026-10-30 - dev host omar: gh + tea auth, repo clones

| Field | Value |
|-------|-------|
| what | Provisioned `ssh omar` (Omarchy 4.0.6 / Arch, x86_64, kernel 7.2.8-9-omarchy, user `omar`) as a dev host for this project: copied `~/.config/gh/{hosts.yml,config.yml}` -> `gh auth status` -> account `satwareAG-ironMike`; `gh auth setup-git` then replaced the mise-absolute helper path with PATH-based `!gh auth git-credential`; installed `tea` 0.16.0 via `pacman -S tea` (Arch `extra`); wrote one tea login (`satware` -> https://git.satware.ai, user `mw`, default) into `~/.config/tea/config.yml`; ran `tea login helper setup`; cloned `https://github.com/satwareAG-ironMike/btt-pad7` to `~/Work/external/btt-pad7` and `https://git.satware.ai/satware.ai/harness` to `~/Work/harness` |
| where | host `omar`, paths `~/Work/external/btt-pad7` (main `1f40a01`), `~/Work/harness` (main `eb68eef2`) |
| when | 2026-10-30 18:17-18:26 (omar host clock) |
| why | user request: gh access to the btt-pad7 repo on omar, clone it, install and configure tea, clone harness |
| result | verified live: `gh auth status` = `satwareAG-ironMike`, scopes `gist, read:org, repo, workflow`; `gh repo view` on the clone = PUBLIC, base `main`; `tea login ls` = `satware`/`mw` (default true); `tea whoami` = `mw` (admin); `tea i ls --repo satware.ai/harness` returned live issues 1639/1638; `printf 'protocol=https\nhost=git.satware.ai\n\n' \| git credential fill` = `username=mw`; both clones on `main` |

Secret-scope note: only the `git.satware.ai` tea login was copied - the `git.jantec.xyz` and `git.wegener.engineering` logins were deliberately not transferred. gh `hosts.yml` (OAuth token) and tea `config.yml` (Gitea token) are copies of the values on `mw`; both files 0600, directories 0700, on `mw` and `omar`. No token value is recorded here.

git global state left on omar: `init.defaultBranch main`, `credential.https://github.com.helper=!gh auth git-credential`, `credential.https://gist.github.com.helper=!gh auth git-credential`, `credential.https://git.satware.ai.helper=!tea login helper`, `user.name Jane Alesi`, `user.email ja@satware.ai` (change it if omar should commit under a different identity).
