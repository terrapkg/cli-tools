# cli-tools
A collection of helpful scripts for contributing to Terra!

### Installing Scripts
1. Download the scripts you want from `/scripts`.
2. Move each script to `/usr/local/bin/` so they can be called as commands:
```sh
sudo mv </path/to/script_filename> /usr/local/bin/ && chmod -x /usr/local/bin/<script_filename>
```
3. Call scripts by running their filename as a command. e.g. `rpmdate` or `ldd-dnf <arg>`.

> [!NOTE]
> You can also run these scripts without moving them to `/usr/local/bin` by calling them with `./path/to/<script_filename>`. 
> You may need to `chmod -x <script_filename>` first to enable executability.

### How to Use

Each script has its own `-h` flag for usage information.

| Name | Useage | Command |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| changelog | Generates info for a changelog entry based on your git config. | `changelog` |
| format-license | Formats the build output of `%cargo_license_summary_online` and `%tauri_summary_license_online` into a proper string for the RPM `License:` tag. | `format-license "<raw license build output>"` |
| ldd-dnf | Finds libraries that a binary dynamically links to, and gets the name of each package that provides them. | `ldd-dnf <path/to/binary.rpm>` |
| getcommit | Fetches and formats the latest commit hash and date for a given git repository for when packaging nightly packages. | `getcommit <git repo url>` |
| panda  | Runs Anda builds in a container. Just pass Anda arguments after Panda. Switch container branch with `-b fxx` | `panda <anda arguments>` |

#### Install

With Terra installed, run:

```sh
dnf install terra-scripts
```

### Plans
- [ ] Once more scripts get added, a CLI tool that includes all the scripts should be created and packaged.
- [ ] Add guide for contributing new scripts.

### Attribution
- `ldd-dnf`, `rpmdate`: june@fyralabs.com
- `format-license`, `getcommit`: jonah@fyralabs.com
- `panda`: jade@fyralabs.com
