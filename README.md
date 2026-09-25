# cli-tools
A collection of helpful scripts for contributing to (and maintaining) [Terra](https://terrapkg.com/)!

## Installation

```sh
# First, install Terra if you haven't already
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Then install this package from Terra
dnf install terra-scripts
```
<details>
<summary>How to install individual scripts</summary>

1. Download the scripts you want from `/scripts`.
2. Move each script to `/usr/local/bin/` so they can be called as commands:
```sh
sudo mv </path/to/script_filename> /usr/local/bin/ && chmod -x /usr/local/bin/<script_filename>
```
3. Call scripts by running their filename as a command. e.g. `rpmdate` or `ldd-dnf <arg>`.

> **Note:**
> You can also run these scripts without moving them to `/usr/local/bin` by calling them with `./path/to/<script_filename>`. 
> You may need to `chmod -x <script_filename>` first to enable executability.

</details>

## How to Use

### Scripts for Packagers/Package Maintainers

| Name | Usage | Command |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| changelog | Generates info for a changelog entry based on your git config by default. You can manually configure it with `--name=""` and `--email=""`. | `changelog [--name=NAME] [--email=EMAIL] ["message"] [--help]` |
| format-license | Formats the build output of `%cargo_license_summary_online` and `%tauri_cargo_license_summary` into a proper string for the RPM `License:` tag. | `format-license "<raw license build output>" [--help]` |
| ldd-dnf | Finds libraries that a binary dynamically links to, and gets the name of each package that provides them. | `ldd-dnf <path/to/binary.rpm> [--help]` |
| getcommit | Fetches and formats the latest commit hash and date for a given git repository for when packaging nightly packages. | `getcommit <git repo url> [--help]` |
| panda  | Runs Anda builds in a container. Just pass Anda arguments after Panda. Switch container branch with `-b fxx` | `panda <anda arguments> [--help]` |
| icedtea-fetch | Fetches [IcedTea](https://openjdk.org/projects/icedtea) archives for use in Java builds. Use `icedtea-fetch -h` to view all flags. | `icedtea-fetch <icedtea-fetch flags> [--help]` |

### Scripts for Repository/Mass Package Maintainers

| Name | Usage | Command |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| satm-grepdel.fish | Batch delete all packages matching a certain exact pattern from a set of repos in Subatomic repo manager. Prints a list of packages to be deleted before confirming deletion, confirm by setting `DRY_RUN=0`. | `satm-grepdel.fish "<pattern>"` |
| satm-rm-stdin.sh | Deletes packages piped in via `stdin` from a single Subatomic repo. An alternative to `satm-grepdel.fish`. | `cat packages.txt \| satm-rm-stdin.sh terra40` where `packages.txt` is a list of packages to delete `subatomic-cli pkg list terra40 \| grep "pattern" \| grep "pattern2" \| satm-rm-stdin.sh terra45` where the grep commands are used to filter the list of packages to delete. |
| sync-branches.sh | Creates a branch sync pull request for when automatic bumps are out of sync across branches, or multiple backports are failing, by cloning `terrapkg/packages` over HTTPS, for a given release branch. | `sync-branches.sh <username> <branch> [-x]` |
| sync-branches-ssh.sh | Same as `sync-branches.sh`, but clones and pushes over SSH instead of HTTPS. | `sync-branches-ssh.sh <username> <branch> [-x]` |
| terra-subtree-build.sh | Builds every Anda project (package) in the current monorepo whose name matches a given pattern. Requires the `CONFIG` env var to be set. | `terra-subtree-build.sh $0 <pattern>` |
| terra_mass_rebuild.py | Prints a formatted list of every package to be pasted into the JSON build Terra workflow, for mass package rebuilds when making new branches/rebuilding frawhide. | `python3 terra_mass_rebuild.py` |

### Plans
- [ ] Once more scripts get added, a CLI tool that includes all the scripts should be created and packaged.
- [ ] Add guide for contributing new scripts.
- [ ] Add `--help` flags to Batch Processing Scripts

### Attribution
- `ldd-dnf`, `changelog`: june@fyralabs.com
- `format-license`, `getcommit`: jonah@fyralabs.com
- `panda`: jade@fyralabs.com
- `icedtea-fetch`, `sync-branches.sh`, `sync-branches-ssh.sh`: roachy@fyralabs.com
- `satm-grepdel.fish`, `satm-rm-stdin`, `terra-subtree-build.sh`: cappy@fyralabs.com
- `terra-mass-rebuild.py`: mado@fyralabs.com
