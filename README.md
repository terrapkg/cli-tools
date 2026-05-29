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
| changelog | Generates metadata for a changelog entry. | `changelog` |
| format-license | Formats the build output of `%cargo_license_summary_online` and `%tauri_summary_license_online` into a human-readable license expression. | `format-license "<raw license build output>"` |
| ldd-dnf | Finds libraries that a package dynamically links to, automatically getting the name of each package that provides them. | `getcommit <git repo url>` |
| getcommit | Fetches and formats the latest commit hash and date for a given git repository. Useful for nightly packages. | `ldd-dnf <path/to/binary.rpm>` |

### Plans
- [ ] Once more scripts get added, a CLI tool that includes all the scripts and corresponding `-h` flags should be created and packaged.
- [ ] Add documentation for how/when/why to use each script.
- [ ] Add guide for contributing new scripts.

### Attribution
- `ldd-dnf`, `rpmdate`: june@fyralabs.com
- `format-license`, `getcommit`: jonah@fyralabs.com
- `panda`: jade@fyralabs.com
