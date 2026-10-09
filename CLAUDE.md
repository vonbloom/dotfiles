# dotfiles

User configuration for `roger` (repo `vonbloom/dotfiles`, checked out at `~/.dotfiles`), managed
with GNU stow. See `~/.claude/CLAUDE.md` for the machine context (immutable arkdep host + `userland`
distrobox).

## Layout and installation

- Each top-level directory is a stow package whose tree mirrors `$HOME`
  (e.g. `zsh/.config/zsh/.zshrc` -> `~/.config/zsh/.zshrc`).
- Packages: `brave`, `git`, `gnupg`, `icons`, `scripts`, `ssh`, `tmux`, `vscode`, `zsh`.
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
  image that `~/distro-builder/userland` builds (packages, exports, box manifest; see its README),
  created and replaced by `userland-update` in the host image. Until 2026-10-09 this repo had a
  `distrobox` package (`default.ini`, a pre-init hook adding the `[cachyos]` and `[aur]` repos, the
  D-Bus services): the boxes were assembled from `archlinux:latest` and upgraded in place.
- `playground` is the box for trying packages: the same image as userland, left alone by
  `userland-update` (`--playground` moves it to userland's image and reinstalls what was added).
  Once a package is worth keeping, add it to distro-builder's `userland/packages.list` (and to the
  exports in `userland/distrobox.ini` if the host must see it). Host software goes in
  `~/distro-builder/image` instead.
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
