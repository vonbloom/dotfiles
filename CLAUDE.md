# dotfiles

@README.md

Machine context (the immutable host and the `userland` distrobox): `~/.claude/CLAUDE.md`. The user
speaks Catalan; code, comments and commit messages are in English.

## Working here

- Usage goes in `README.md` (and `gnupg/README.md`); this file keeps the implementation notes and
  the pitfalls already hit. A fact lives in one of them.
- This repository is public: document only the configuration itself (what it does, how and why),
  in files, comments and commit messages. Infrastructure details stay out: addresses, servers and
  their jobs, VM and container IDs, Syncthing device and folder IDs, backup locations, work
  projects. They belong in the private homelab repo (`docs/`), which a document may point to.
- Never commit secrets or private keys.
- Shell scripts: `#!/usr/bin/env bash` (or `/bin/sh` when POSIX is enough), tab indentation.
- Commits: short imperative English sentence, no prefix (e.g. "Add vscode package"), GPG-signed
  (`commit.gpgsign = true` in `git/.config/git/config`).

## Host vs container

- Config that depends on installed software must work where it is missing (see `_have` in
  `zsh/.config/zsh/utils.zsh`) or be kept per environment (`${CONTAINER_ID:-host}`).
- Wrappers in `~/.local/bin` are on the PATH in both places. Do not shadow system commands with a
  wrapper of the same name (e.g. `pacman`); the distrobox-exported wrappers handle this with
  `$CONTAINER_ID` checks.
- The boxes are not defined here any more: they come from the userland image that
  `~/Projectes/distro-builder/userland` builds (packages, exports, box manifest; see its README),
  created and replaced by `userland-update` in the host image. Until 2026-10-09 this repo had a
  `distrobox` package (`default.ini`, a pre-init hook adding the `[cachyos]` and `[aur]` repos, the
  D-Bus services): the boxes were assembled from `archlinux:latest` and upgraded in place.
- A package worth keeping from `playground` also goes to the exports in distro-builder's
  `userland/distrobox.ini` if the host must see it. Host software goes in distro-builder's
  `bootc/layers` instead.
- `distrobox-host-exec` does not work here (host-spawn needs flatpak, which the host lacks). Never
  run podman in local mode inside a container (e.g. `--remote=false` or the host binary from
  `/run/host`): it deletes the host's rootless `pause.pid` (the image makes `podman` the remote
  client).
- distrobox sets `SHELL` to the shell's name without a path (`zsh`) in its boxes: tools that need
  an absolute `$SHELL` fail there (ssh's `Match exec` and `ProxyCommand`; see the `ssh` package).
- gvfs (Thunar `smb://` mounts) and xfconfd (Thunar's preferences) run in userland, but D-Bus
  activation uses the host's session bus: `userland-update` installs their service files from the
  image in `~/.local/share/dbus-1/services`.
- `icons/`: the two colour icons (Home `go-home`, Recent `document-open-recent`) replace the ones
  Thunar's side pane takes from AdwaitaLegacy, built from Adwaita's folder-download and clock. The
  install hook sets the theme with gsettings (dconf is shared by the host and userland); the
  light/dark hook in the image only changes `gtk-theme`.
- VS Code must stay Microsoft's build (`visual-studio-code-bin` from `[aur]`): CachyOS only has
  Code-OSS (`code`) and `vscodium`, which cannot use the Dev Containers extension the work
  projects rely on.

## zsh

- `ZDOTDIR=$HOME/.config/zsh` is set in `/etc/zsh/zshenv` and the `XDG_*` variables in
  `/etc/profile.d/xdg-vars.sh`, both in distro-builder's base layer
  (`bootc/layers/base/overlay/etc/`). The container inherits them from the host environment.
- `.zshrc` sources `utils.zsh`, `history.zsh`, `prompt.zsh`, `alias.bash` (in bash emulation),
  then `compinit` and `plugins.zsh`. tmux comes from the sway binding in the image
  (`foot tmux new-session -A -s main`), never from `.zshrc`.
- The plugins are handled by the autoloaded functions in `zsh/.local/share/zsh/functions`
  (`install-`, `source-`, `update-zsh-plugins`). Order matters: `compinit`, then `fzf --zsh` (it
  binds Tab to its own completion), then the plugins, so that fzf-tab takes Tab back and
  syntax-highlighting wraps every widget.
- The completion dump is per environment: `$XDG_CACHE_HOME/zsh/zcompdump-${CONTAINER_ID:-host}`.
- History lives in `$XDG_CACHE_HOME/zsh/history` (the dir is created by `zsh/install`).

## Scripts (`scripts/.local/bin`, `scripts/.local/share/applications`)

- `userland` / `playground`: `playground` is a symlink to `userland` (box taken from `$0`). Inside
  its own box it runs the command directly; from another container it refuses. The aliases `ul`
  and `pg` shadow util-linux `ul`/`pg` in interactive shells only.
- `vm-console`: the ticket comes from `pvesh create /nodes/<node>/qemu/<vmid>/spiceproxy` over root
  SSH and lasts seconds, so the `.vv` is written to `~/.cache` and opened at once (remote-viewer
  deletes it). Errors also go to `notify-send`: the launcher entry has no terminal. Its `Exec` is an
  absolute path: the sway session's PATH lacks `~/.local/bin`.
- `note`: with vim/nvim the new lines go into the buffer through `-c` (strings quoted as Vim
  literals, so any note name works): the old script `touch`ed the file first and left empty notes.
  Inside tmux it runs `tmux new-window` with an argument list, no shell. On the host, `export`
  reruns itself in userland (`pandoc-cli`, `typst`); `wikilinks_title_after_pipe` reads Obsidian's
  links. Adopted from the old Ansible dotfiles (`roles/system/files/bin/note`, 2025). Testing:
  point `NOTES_DIR` at a scratch directory, `EDITOR` at a stand-in that runs
  `nvim --headless "$@" -c wq`, and unset `TMUX`, or the note opens in a window of the real tmux
  session.

## gnupg and ssh

- `./install gnupg` creates `~/.gnupg` with mode 700. `gpg-backup` must stay verified; test
  changes with throwaway keys in a temp `GNUPGHOME`, never against `~/.gnupg`.
- `gpg-agent.conf` pins `pinentry-gtk`: since gnome-keyring brought gcr into the image
  (2026-10-08), the `/usr/bin/pinentry` wrapper picks pinentry-gnome3 first, a GNOME prompt with
  another style. A plain file instead of the stow link (as on the P14s until then) misses changes:
  check with `ls -la ~/.gnupg`.
- `ssh/.ssh/config` runs `gpg-connect-agent updatestartuptty` before every connection
  (`KnownHostsCommand /bin/sh -c ...`, also for git, scp and Ansible): the ssh-agent protocol does
  not say where to ask for the passphrase, so the agent asks on the terminal (`GPG_TTY`, exported by
  `.zshrc`) and display it was last pointed at. That gives a dialog on the desktop and a prompt
  in the terminal over SSH (without it, ssh in an SSH session could not unlock the key and fell back
  to the keys in `~/.ssh`: the T480's old `id_rsa` asked for its passphrase). Until 2026-10-09
  `.zshrc` did it in every new shell: after an SSH session to the P14s closed, the agent still asked
  on its gone terminal and ssh on the desktop failed with "agent refused operation". `Match exec`
  (the first version, 2026-10-09) runs through `$SHELL`, which distrobox sets to `zsh` without a
  path in its boxes: ssh refused it ("Shell "zsh" is not executable") and Ansible and git in
  userland broke. KnownHostsCommand runs its program directly (a literal absolute path: tokens and
  `${HOME}` only expand in the arguments), while checking the host key, before authenticating.
- `sshcontrol` lists both authentication subkeys.

## Syncthing

- The unit runs `distrobox-enter --name userland -- syncthing serve` under the host's systemd user
  manager; the install hook enables it on the host only. Each machine has its own device ID.
- The laptops dial the server, so nftables opens nothing. Notes is outside `~/Documents` (until
  2026-10-20 in `~/Documents/notes`) so that Documents can be a folder of its own without the
  phone: a folder inside another synced folder would be synced by both. The first merge of the
  laptops' copies (2026-10-20) compared sha256 manifests of every copy, resolved the one conflict
  by hand and moved code out of Documents.
- Stopping the unit stops Syncthing cleanly (conmon passes SIGTERM on and waits; podman exec itself
  exits 1, hence `SuccessExitStatus=1`). When `userland-update` replaces the box Syncthing dies with
  it and `Restart=always` starts it in the new one; meanwhile `StandardInputText=n` answers
  distrobox-enter's "Create it now? [Y/n]", which an empty stdin takes as yes (a box from
  `archlinux:latest`).

## Termux (phone)

- `termux/` is not a stow package (`install` skips it, `NOT_PACKAGES`): Termux:Widget only runs
  scripts whose real path is in `~/.shortcuts`, so a stow link would not work.
- The Xiaomi permission was found on 2026-10-12 (without it the note was written but Markor did not
  open). The Xiaomi launcher has no 1x1 "Termux shortcut" in its widget picker, only the list
  widget; dynamic shortcuts did not show at once (2026-10-12), and launcher search does not find
  them. The `tasks/` check uses the real path, hence the symlink for the label (termux-widget
  `ShortcutFile`, `TermuxWidgetProvider`).
- `Nota del dia`: Markor (2.16.1) cannot get a file by path in an intent (the
  `markor://open?path=` deep link is only in master since 2026-08), but it resolves
  `content://<any authority>/storage/...` to the file itself and edits it in place: the script
  sends `content://com.termux.files<real path>` to `DocumentActivity`, falling back to
  `termux-open`. The path must be the real `/storage/emulated/0/...` (`realpath`), not
  `~/storage/shared/...`. The lines are written before opening (Markor takes no buffer), so a
  last `## HH:MM` with nothing under it gets its time updated instead of a new one.
