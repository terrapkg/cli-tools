# cli-tools
Helpful scripts for contributing to Terra

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

### Plans
- [ ] Once more scripts get added, a CLI tool that includes all the scripts and corresponding `-h` flags should be created.
- [ ] Add documentation for how/when/why to use each script.
- [ ] Add guide for contributing new scripts.
