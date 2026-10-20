# dotfiles

User configuration for `roger` (repo `vonbloom/dotfiles`, checked out at `~/.dotfiles`), managed
with GNU stow. See `~/.claude/CLAUDE.md` for the machine context (immutable arkdep host + `userland`
distrobox).

## Layout and installation

- Each top-level directory is a stow package whose tree mirrors `$HOME`
  (e.g. `zsh/.config/zsh/.zshrc` -> `~/.config/zsh/.zshrc`).
- Packages: `brave`, `git`, `gnupg`, `icons`, `scripts`, `ssh`, `syncthing`, `tmux`, `vscode`,
  `zsh`.
- `./install [package]` (run from the repo root, it uses `$(pwd)`) restows one package or all of
  them. It uses `--no-folding`, so stow links individual files, never whole directories. Prefer
  it over calling `stow` directly; if you do, pass `--no-folding -t ~`.
- A package can have an executable `install` hook at its root (`zsh/install`, `vscode/install`),
  run after stowing. `install` and `README.md` files are not stowed.
- Adding a file to a package only takes effect after restowing that package.
- `.gitignore` excludes runtime files (`.zcompdump`, history, GnuPG keyrings and trustdb). Never
  commit secrets or private keys.

## Host vs container

- `$HOME` is shared between the host and the distroboxes (`userland`, `playground`), so every file
  here is used in all of them. Config that depends on installed software must work where it is
  missing (see `_have` in `zsh/.config/zsh/utils.zsh`) or be kept per environment
  (`${CONTAINER_ID:-host}`).
- Wrappers in `~/.local/bin` are on the PATH in both places. Do not shadow system commands with a
  wrapper of the same name (e.g. `pacman`); the distrobox-exported wrappers handle this with
  `$CONTAINER_ID` checks.
- The boxes (`userland`, `playground`) are not defined here any more: they come from the userland
  image that `~/Projectes/distro-builder/userland` builds (packages, exports, box manifest; see its README),
  created and replaced by `userland-update` in the host image. Until 2026-10-09 this repo had a
  `distrobox` package (`default.ini`, a pre-init hook adding the `[cachyos]` and `[aur]` repos, the
  D-Bus services): the boxes were assembled from `archlinux:latest` and upgraded in place.
- `playground` is the box for trying packages: the same image as userland, left alone by
  `userland-update` (`--playground` moves it to userland's image and reinstalls what was added).
  Once a package is worth keeping, add it to distro-builder's `userland/packages.list` (and to the
  exports in `userland/distrobox.ini` if the host must see it). Host software goes in
  `~/Projectes/distro-builder/image` instead.
- `distrobox-host-exec` does not work here (host-spawn needs flatpak, which the host lacks). Never
  run podman in local mode inside a container (e.g. `--remote=false` or the host binary from
  `/run/host`): it deletes the host's rootless `pause.pid` (the image makes `podman` the remote
  client).
- distrobox sets `SHELL` to the shell's name without a path (`zsh`) in its boxes: tools that need
  an absolute `$SHELL` fail there (ssh's `Match exec` and `ProxyCommand`; see the `ssh` package).
- gvfs (Thunar `smb://` mounts) and xfconfd (Thunar's preferences) run in userland, but D-Bus
  activation uses the host's session bus: `userland-update` installs their service files from the
  image in `~/.local/share/dbus-1/services`.
- `icons/` is the icon theme `Adwaita-Sidebar`: Adwaita plus colour versions of the two icons
  Thunar's side pane takes from AdwaitaLegacy (Home `go-home`, Recent `document-open-recent`,
  built from Adwaita's folder-download and clock). Its install hook sets it with gsettings (dconf
  is shared by the host and userland); the light/dark hook in the image only changes `gtk-theme`.
- VS Code must stay Microsoft's build (`visual-studio-code-bin` from `[aur]`): CachyOS only has
  Code-OSS (`code`) and `vscodium`, which cannot use the Dev Containers extension the `tramit-*`
  projects rely on.

## zsh

- `ZDOTDIR=$HOME/.config/zsh` is set in `/etc/zsh/zshenv` and the `XDG_*` variables in
  `/etc/profile.d/xdg-vars.sh`; both come from the host image
  (`~/Projectes/distro-builder/image/arkdep-build.d/depends/generic/overlay/post_install/etc/`), not from this
  repo. The container inherits them from the host environment.
- `.zshrc` sources `utils.zsh`, `history.zsh`, `prompt.zsh`, `alias.bash` (in bash emulation),
  then `compinit` and `plugins.zsh`. It does not start tmux: only the sway binding `Win+Enter`
  (`foot tmux new-session -A -s main`, in the image) does; `Win+Shift+Enter`, VS Code, SSH and
  ttys get a plain shell.
- Plugins (`fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`) are cloned from GitHub into
  `$XDG_DATA_HOME/zsh/plugins` by the autoloaded functions in `zsh/.local/share/zsh/functions`
  (`install-`, `source-`, `update-zsh-plugins`). `fzf-tab` needs `fzf` installed, otherwise
  ambiguous Tab completion does nothing. Order matters: `compinit`, then `fzf --zsh` (it binds
  Tab to its own completion), then the plugins, so that fzf-tab takes Tab back and
  syntax-highlighting wraps every widget.
- The completion dump is per environment: `$XDG_CACHE_HOME/zsh/zcompdump-${CONTAINER_ID:-host}`.
- History lives in `$XDG_CACHE_HOME/zsh/history` (the dir is created by `zsh/install`).

## Scripts (`scripts/.local/bin`, `scripts/.local/share/applications`)

- `arkdep-diff`: package diff between the running deployment and the previous one (run after
  rebooting into a new deployment).
- `userland [cmd...]` / `playground [cmd...]`: `distrobox enter <box> -- cmd`, or a shell with
  no arguments. `playground` is a symlink to `userland` (box taken from `$0`); aliased to `ul`
  and `pg` in `alias.bash` (shadowing util-linux `ul`/`pg` in interactive shells only). Inside
  its own box it runs the command directly; from another container it refuses.
- `vm-console [vmid]`: the SPICE console of a VM on zeus (default 206, the Windows VM; homelab
  `docs/guests.md`) in `remote-viewer` (userland), starting the VM if it is stopped. The ticket
  comes from `pvesh create /nodes/zeus/qemu/<vmid>/spiceproxy` over root SSH and lasts seconds,
  so the `.vv` is written to `~/.cache` and opened at once (remote-viewer deletes it). Errors also
  go to `notify-send`. `scripts/.local/share/applications/vm-console-windows.desktop` puts it in
  the launcher as "Windows" (absolute `Exec`: the sway session's PATH lacks `~/.local/bin`).
- `note`: notes in `~/Notes` (the Syncthing folder Notes; `NOTES_DIR` overrides it).
  `note` opens today's `YYYY-MM-DD.md` (new: `# YYYY-MM-DD`; existing: a new `## HH:MM` section),
  `note [add] <name>` opens or starts `<name>.md` (`# <name>`), `note find` picks one with fzf,
  `note export <name> [pdf]` makes a PDF with pandoc and typst (`pandoc-cli`, `typst` in userland;
  on the host it reruns itself there through `userland`; `wikilinks_title_after_pipe` reads
  Obsidian's `[[...]]` links and `![[image.png]]` embeds). With vim/nvim the new lines go into the
  buffer through `-c` (strings quoted as Vim literals, so any note name works), so nothing is
  written until you save: the old script `touch`ed the file first and left empty notes. Inside
  tmux it opens a new window (`tmux new-window` with an argument list, no shell). Adopted from the
  old Ansible dotfiles (`roles/system/files/bin/note`, 2025). Testing: point `NOTES_DIR` at a
  scratch directory, `EDITOR` at a stand-in that runs `nvim --headless "$@" -c wq`, and unset
  `TMUX`, or the note opens in a window of the real tmux session.

## gnupg

- GnuPG config plus `gpg-backup`, `gpg-restore` and `install-ssh-key` (SSH uses the GPG agent;
  `SSH_AUTH_SOCK` is set in `.zprofile`). `./install gnupg` creates `~/.gnupg` with mode 700.
- This key is the root of everything: it decrypts the homelab vault password, and the vault holds
  the distro-builder signing key. `gpg-backup` must stay verified (it imports the backup into a
  throwaway keyring before writing it); test changes with throwaway keys in a temp `GNUPGHOME`,
  never against `~/.gnupg`.
- `gpg-agent.conf` pins `pinentry-gtk`: since gnome-keyring brought gcr into the image
  (2026-10-08), the `/usr/bin/pinentry` wrapper picks pinentry-gnome3 first, a GNOME prompt with
  another style. A plain file instead of the stow link (as on the P14s until then) misses changes:
  check with `ls -la ~/.gnupg`.
- `ssh/.ssh/config` runs `gpg-connect-agent updatestartuptty` before every connection
  (`KnownHostsCommand /bin/sh -c ...`, also for git, scp and Ansible): the ssh-agent protocol does
  not say where to ask for the passphrase, so the agent asks on the terminal (`GPG_TTY`, exported by
  `.zshrc`) and display it was last pointed at. That gives a dialog on the desktop and a prompt in
  the terminal over SSH (without it, ssh in an SSH session could not unlock the key and fell back to
  the keys in `~/.ssh`: the T480's old `id_rsa` asked for its passphrase). Until 2026-10-09 `.zshrc`
  did it in every new shell: after an SSH session to the P14s closed, the agent still asked on its
  gone terminal and ssh on the desktop failed with "agent refused operation". `Match exec` (the
  first version, 2026-10-09) runs through `$SHELL`, which distrobox sets to `zsh` without a path in
  its boxes: ssh refused it ("Shell "zsh" is not executable") and Ansible and git in userland broke.
  KnownHostsCommand runs its program directly (a literal absolute path: tokens and `${HOME}` only
  expand in the arguments), while checking the host key, before authenticating. The config only has
  generic settings; hosts of one machine go in `~/.ssh/config.d/` (included, not in the repo). When
  a machine already has a `~/.ssh/config`, move it to `~/.ssh/config.d/local` before `./install ssh`
  (stow does not overwrite files).
- `sshcontrol` lists both authentication subkeys. gpg-agent replaces the stow link with a plain
  file when `ssh-add` adds a key: copy it back into the package afterwards.

## Syncthing

- `syncthing/.config/systemd/user/syncthing.service` runs Syncthing from the userland box
  (`distrobox-enter --name userland -- syncthing serve`) under the host's systemd user manager; the
  install hook enables and starts it (on the host only). Config, keys (each machine its own device
  ID) and database in `~/.local/state/syncthing`, web UI on http://127.0.0.1:8384.
- Folders: Notes (`3gq8w-ivpc9`, `~/Notes`; the phone keeps `Documents/notes`), Documents
  (`roger-documents`, `~/Documents`) and Imatges (`roger-imatges`, `~/Imatges`), the last two
  with the laptops only, all with roger's instance on the server (CT 112,
  `tcp://192.168.2.34:22001`; homelab `docs/guests.md`), which keeps the versions. A star: the
  laptops and the phone pair only with the server. The laptops dial it, so nftables opens
  nothing. Notes is outside `~/Documents` (until 2026-10-20 in `~/Documents/notes`) so that
  Documents can be a folder of its own without the phone: a folder inside another synced folder
  would be synced by both.
- What goes where in the home: git repositories in `~/Projectes` (synced by git), files to keep in
  `~/Documents` and `~/Imatges` (Syncthing), `~/Baixades` neither synced nor backed up. A new
  laptop that already has files in a folder merges them with the others' on its first sync: files
  that exist on one side only are copied, a path with different contents keeps the newer one and
  a `.sync-conflict-*` copy of the other, deletions are not carried over. Compare the copies first
  (2026-10-20: sha256 manifests of every copy, the one conflict resolved by hand, code moved out of
  Documents).
- Stopping the unit stops Syncthing cleanly (conmon passes SIGTERM on and waits; podman exec itself
  exits 1, hence `SuccessExitStatus=1`). When `userland-update` replaces the box Syncthing dies with
  it and `Restart=always` starts it in the new one; meanwhile `StandardInputText=n` answers
  distrobox-enter's "Create it now? [Y/n]", which an empty stdin takes as yes (a box from
  `archlinux:latest`). Syncthing keeps userland running, so `userland-update` always asks first.

## Termux (phone)

- `termux/` is not a stow package (`install` skips it, `NOT_PACKAGES`): Termux:Widget only runs
  scripts whose real path is in `~/.shortcuts`, so a stow link would not work. Copy them on the
  phone (Termux and Termux:Widget from the same source, F-Droid; `termux-setup-storage` once):
  `mkdir -p ~/.shortcuts/tasks && curl -fsSL "https://raw.githubusercontent.com/vonbloom/dotfiles/main/termux/shortcuts/Nota%20del%20dia" -o ~/.shortcuts/tasks/"Nota del dia" && chmod 700 ~/.shortcuts/tasks/"Nota del dia"`.
  `tasks/` runs without a terminal; starting Markor from the background needs Termux's "Display
  over other apps" permission, and on the Xiaomi also "Display pop-up windows while running in the
  background" (without it the note was written but Markor did not open, 2026-10-12); or put it in
  `~/.shortcuts` itself: a terminal flashes. The Xiaomi launcher has no 1x1 "Termux shortcut" in
  its widget picker, only the list widget. Dynamic shortcuts work too ("Create shortcuts" in the
  Termux:Widget app, then a long press of its icon; not at once, 2026-10-12, and launcher search
  does not find them). Their label is the path under `~/.termux/widget/dynamic_shortcuts`
  ("tasks/Nota del dia"), but the `tasks/` check uses the real path, so the phone has a symlink
  `dynamic_shortcuts/Nota del dia` -> `~/.shortcuts/tasks/Nota del dia`: labelled "Nota del dia",
  run in the background, one copy to update (termux-widget `ShortcutFile`, `TermuxWidgetProvider`). The notes
  folder is `~/storage/shared/Documents/notes` unless `~/.config/notes-dir` holds another path
  (find it with `find ~/storage/shared -maxdepth 5 -name .stfolder`).
- `Nota del dia`: today's note like `note`, then Markor. Markor (2.16.1) cannot get a file by path
  in an intent (the `markor://open?path=` deep link is only in master since 2026-08), but it
  resolves `content://<any authority>/storage/...` to the file itself and edits it in place: the
  script sends `content://com.termux.files<real path>` to `DocumentActivity`, falling back to
  `termux-open`. The path must be the real `/storage/emulated/0/...` (`realpath`), not
  `~/storage/shared/...`. The lines are written before opening (Markor takes no buffer), so a
  last `## HH:MM` with nothing under it gets its time updated instead of a new one.

## Conventions

- Shell scripts: `#!/usr/bin/env bash` (or `/bin/sh` when POSIX is enough), tab indentation.
- Commits: short imperative English sentence, no prefix (e.g. "Add vscode package"). Commits are
  GPG-signed (`commit.gpgsign = true` in `git/.config/git/config`).

## Secret Service

- Brave and VS Code (userland box) keep their secrets in the host's gnome-keyring (image, sway layer:
  unlocked at the tty login by pam_gnome_keyring), reached on the shared session bus. On sway they do
  not detect it: `brave/.config/brave-flags.conf` and the `vscode` install hook (key added to
  `~/.vscode/argv.json`) set `--password-store=gnome-libsecret`. Brave still reads the data it
  encrypted with its "basic" store before; VS Code may ask to sign in again.
