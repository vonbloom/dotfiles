# dotfiles

User configuration for an immutable Arch-based laptop: the host images and the `userland`
distrobox of [distro-builder](https://github.com/vonbloom/distro-builder), managed with GNU stow.
`$HOME` is shared between the host and the distroboxes (`userland`, `playground`), so every file
here works in all of them.

## Installation

```sh
git clone https://github.com/vonbloom/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install          # every package
./install zsh      # one package
```

- Each top-level directory is a stow package whose tree mirrors `$HOME`
  (`zsh/.config/zsh/.zshrc` -> `~/.config/zsh/.zshrc`). `./install`, run from the repository root,
  restows with `--no-folding`: stow links individual files, never whole directories. Run it again
  after adding a file to a package; when calling `stow` directly, pass `--no-folding -t ~`.
- A package can have an executable `install` hook at its root, run after stowing. `install` and
  `README.md` files are not stowed.
- stow never overwrites a file: move an existing one aside first (an existing `~/.ssh/config` goes
  to `~/.ssh/config.d/local`, which the package's config includes).
- Runtime files (`.zcompdump`, history, GnuPG keyrings and trustdb) are ignored by git.

## Packages

| Package | What it holds |
|---|---|
| `brave` | `brave-flags.conf`: the passwords in the host's Secret Service (below) |
| `git` | the user and GPG-signed commits |
| `gnupg` | GnuPG and gpg-agent (also the SSH agent), `gpg-backup`, `gpg-restore`, `install-ssh-key`: [gnupg/README.md](gnupg/README.md) |
| `icons` | the icon theme `Adwaita-Sidebar`: Adwaita plus colour Home and Recent icons in Thunar's side pane, set by its hook |
| `scripts` | `userland`, `playground`, `note`, `arkdep-diff`, `vm-console` (below) |
| `ssh` | generic settings only; the hosts of one machine go in `~/.ssh/config.d/` (included, not in the repository) |
| `syncthing` | a user unit that runs Syncthing from the userland box (below) |
| `tmux` | vi keys, `C-a` as a second prefix, `h`/`j`/`k`/`l` between panes, the mouse, the status bar at the top |
| `vscode` | the user settings (podman for the dev containers); its hook installs the Dev Containers extension and the Secret Service flag |
| `zsh` | the shell (below) |
| `termux/` | not a stow package: a shortcut for the phone (below) |

## zsh

- `ZDOTDIR` (`~/.config/zsh`) and the `XDG_*` variables come from the host image, not from here.
- tmux starts only from the sway binding `Win+Enter` (session `main`); `Win+Shift+Enter`, VS Code,
  SSH and the ttys get a plain shell.
- The plugins (`fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`) are cloned from
  GitHub into `$XDG_DATA_HOME/zsh/plugins` the first time; `update-zsh-plugins` updates them.
  `fzf-tab` needs `fzf`: without it an ambiguous Tab completion does nothing.
- The aliases are in `alias.bash`, among them `ul` and `pg` for the two boxes.

## Scripts

- `userland [command...]`, `playground [command...]` (aliases `ul`, `pg`): run a command in that
  box, or open a shell in it. `playground` is the box for trying packages: an update of the boxes
  leaves it alone, and the packages worth keeping go to distro-builder's `userland/packages.list`.
- `note`: notes in `~/Notes` (`NOTES_DIR` overrides it). `note` opens today's `YYYY-MM-DD.md`
  (an existing one gets a new `## HH:MM` section), `note [add] <name>` opens or starts
  `<name>.md`, `note find` picks one with fzf, `note export <name> [pdf]` makes a PDF with pandoc
  and typst (Obsidian's `[[...]]` links and `![[image]]` embeds included). With vim or nvim
  nothing is written until you save; inside tmux the note opens in a new window.
- `arkdep-diff`: the package changes between the running arkdep deployment and the previous one.
- `vm-console [vmid]`: the SPICE console of a Proxmox VM in `remote-viewer`, starting the VM if it
  is stopped; the launcher entry "Windows" opens one VM's console.

## Syncthing

`./install syncthing`, on the host, enables a user unit that runs Syncthing from the userland
box. Its state (config, keys, database) is in `~/.local/state/syncthing`, the web UI on
http://127.0.0.1:8384. Three folders, each shared with a Syncthing instance on a server that keeps
the versions: Notes (`~/Notes`, also with the phone), Documents (`~/Documents`) and Imatges
(`~/Imatges`). The laptops and the phone pair only with the server.

What goes where in the home: git repositories in `~/Projectes` (synced by git), files to keep in
`~/Documents` and `~/Imatges`, `~/Baixades` neither synced nor backed up. A laptop that already has
files in a folder merges them with the others' on its first sync: files on one side only are
copied, a path with different contents keeps the newer one plus a `.sync-conflict-*` copy of the
other, and deletions are not carried over. Compare the copies first.

Syncthing keeps userland running, so `userland-update` always asks before replacing the box; the
unit starts Syncthing again in the new one.

## Termux (phone)

`termux/shortcuts/Nota del dia` is a Termux:Widget shortcut: today's note, as `note` makes it,
opened in Markor. Install Termux and Termux:Widget from the same source (F-Droid), run
`termux-setup-storage` once, then:

```sh
mkdir -p ~/.shortcuts/tasks && curl -fsSL "https://raw.githubusercontent.com/vonbloom/dotfiles/main/termux/shortcuts/Nota%20del%20dia" -o ~/.shortcuts/tasks/"Nota del dia" && chmod 700 ~/.shortcuts/tasks/"Nota del dia"
```

- `tasks/` runs without a terminal. Opening Markor from the background needs Termux's "Display
  over other apps" permission, and on Xiaomi phones also "Display pop-up windows while running in
  the background". A shortcut in `~/.shortcuts` itself works without them, but a terminal flashes.
- The notes folder is `~/storage/shared/Documents/notes` unless `~/.config/notes-dir` holds
  another path (find it with `find ~/storage/shared -maxdepth 5 -name .stfolder`).
- A launcher icon: "Create shortcuts" in the Termux:Widget app, then a long press of its icon. The
  label is the path under `~/.termux/widget/dynamic_shortcuts`, so a symlink
  `dynamic_shortcuts/Nota del dia` -> `~/.shortcuts/tasks/Nota del dia` gives it the label
  "Nota del dia" and keeps it running in the background.

## Secret Service

Brave and VS Code (userland box) keep their secrets in the host's gnome-keyring, unlocked at the
login. On sway they do not detect it, so `brave-flags.conf` and the `vscode` hook (in
`~/.vscode/argv.json`) set `--password-store=gnome-libsecret`. Brave still reads what it stored
with its "basic" store before; VS Code may ask to sign in again.
