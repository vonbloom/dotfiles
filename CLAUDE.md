# dotfiles

User configuration for `roger` (repo `vonbloom/dotfiles`, checked out at `~/.dotfiles`), managed
with GNU stow. See `~/.claude/CLAUDE.md` for the machine context (immutable arkdep host + `userland`
distrobox).

## Layout and installation

- Each top-level directory is a stow package whose tree mirrors `$HOME`
  (e.g. `zsh/.config/zsh/.zshrc` -> `~/.config/zsh/.zshrc`).
- Packages: `brave`, `distrobox`, `git`, `gnupg`, `icons`, `scripts`, `tmux`, `vscode`, `zsh`.
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
  here is used in all of them. Config that depends on installed software must work where it is missing (see `_have` in
  `zsh/.config/zsh/utils.zsh`) or be kept per environment (`${CONTAINER_ID:-host}`).
- Wrappers in `~/.local/bin` are on the PATH in both places. Do not shadow system commands with a
  wrapper of the same name (e.g. `pacman`); the distrobox-exported wrappers handle this with
  `$CONTAINER_ID` checks.
- Containers are defined in `distrobox/.config/distrobox/default.ini`. `[playground]` is the bare
  base (image, `[aur]` repo, fonts, podman remote) and `[userland]` is `include=playground` plus
  its packages and exports. Included keys accumulate and cannot be cleared, so keep
  `[playground]` to what its hooks need (`fontconfig` for `fc-cache`); never put userland's
  packages or exports there.
- `playground` is a throwaway box for trying packages. Once something is worth keeping, add it to
  `[userland]` (`additional_packages`, and `exported_apps`/`exported_bins` if needed) and install
  it in userland. Recreate a box with
  `distrobox assemble create --replace --file ~/.config/distrobox/default.ini --name <box>`.
  Host software goes in `~/distro-builder/image` instead.
- `distrobox-host-exec` does not work here (host-spawn needs flatpak, which the host lacks). Never
  run podman in local mode inside a container (e.g. `--remote=false` or the host binary from
  `/run/host`): it deletes the host's rootless `pause.pid`.
- gvfs (Thunar `smb://` mounts) runs in userland, but D-Bus activation uses the host's session
  bus: `distrobox/.local/share/dbus-1/services/org.gtk.vfs.Daemon.service` starts
  `/usr/lib/gvfsd` in the container on demand. Same for xfconfd (`org.xfce.Xfconf.service`),
  which stores Thunar's preferences: without it Thunar forgets them on every start.
- `icons/` is the icon theme `Adwaita-Sidebar`: Adwaita plus colour versions of the two icons
  Thunar's side pane takes from AdwaitaLegacy (Home `go-home`, Recent `document-open-recent`,
  built from Adwaita's folder-download and clock). Its install hook sets it with gsettings (dconf
  is shared by the host and userland); the light/dark hook in the image only changes `gtk-theme`.
- `pre_init_distrobox_assemble.sh` (runs as root on every container start) adds two repos after
  Arch's `[core]`/`[extra]`, in priority order: `[cachyos]` (generic x86_64 only, not the `-v3`
  repos, so the base stays Arch) and `[aur]`, prebuilt AUR packages at `http://192.168.2.50/aur` (built by `~/distro-builder/aur`).
  A package in both (e.g. `brave-bin`) comes from `[cachyos]`. Plain `pacman -Syu` updates
  everything, no AUR helper. `[aur]` is signed by the build server: the hook trusts
  `distrobox/.config/distrobox/distro-builder.asc` (a copy of distro-builder's `keys/`; replace
  both if the key changes) and sets `SigLevel = Required`, also in existing containers. The Arch image has no local pacman master key, so the hook runs
  `pacman-key --init` before lsigning the CachyOS key.
- The hook also removes a leftover `/var/lib/pacman/db.lck`: the first setup of `userland` takes
  minutes (`deploy-userland` in the image starts it at any login, SSH too), and ending the session
  or rebooting meanwhile stops the container in the middle of a pacman transaction; every later
  start then failed with "unable to lock database" (seen on the bootc T480 rehearsal, 2026-10-08).
- Init hooks are joined with `&&` and a failing one aborts the box setup before `assemble` exports
  the apps and binaries (exports only happen when a box is created): `fc-cache -f || true`.
- Package hooks that call `systemctl` fail in the boxes (no systemd as PID 1). The hook disables
  them with a `/dev/null` link of the same name in `/etc/pacman.d/hooks`: so far openssh's
  `10-openssh-mark-sshd-for-restart.hook` (openssh 10.6, every upgrade). Add new ones there.
- VS Code must stay Microsoft's build (`visual-studio-code-bin` from `[aur]`): CachyOS only has
  Code-OSS (`code`) and `vscodium`, which cannot use the Dev Containers extension the `tramit-*`
  projects rely on.

## zsh

- `ZDOTDIR=$HOME/.config/zsh` is set in `/etc/zsh/zshenv` and the `XDG_*` variables in
  `/etc/profile.d/xdg-vars.sh`; both come from the host image
  (`~/distro-builder/image/arkdep-build.d/depends/generic/overlay/post_install/etc/`), not from this
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

## Scripts (`scripts/.local/bin`)

- `arkdep-diff`: package diff between the running deployment and the previous one (run after
  rebooting into a new deployment).
- `userland [cmd...]` / `playground [cmd...]`: `distrobox enter <box> -- cmd`, or a shell with
  no arguments. `playground` is a symlink to `userland` (box taken from `$0`); aliased to `ul`
  and `pg` in `alias.bash` (shadowing util-linux `ul`/`pg` in interactive shells only). Inside
  its own box it runs the command directly; from another container it refuses.

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
- `sshcontrol` lists both authentication subkeys. gpg-agent replaces the stow link with a plain
  file when `ssh-add` adds a key: copy it back into the package afterwards.

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
