# Eason Jump
a cli tool `j` ( it's not autojump... it's my version)

## Features
- record cd history in graph (per session), (hijack `cd` after init) v
- init, or denint (auto start) v
- activate or deactivate (per session) 
- create a path alias v
- remove a path alias v
- jump to path alias v
- list all path alias v
- back to previous location (if existed) v
- go to next location (if existed) v
- show to history graph v
- clean up history
- self uninstallation

## Usage
```
Usage:
    j COMMAND
    j <path_alias>          cd to the path of path_alias
    j <path_alias> <path>   save path as path_alias
Commands:
    init                    modify `~/.bashrc`, hijack `cd` to record history
    deinit                  undo init, deactivate
    ls                      list all alias
    f                       go to next location (if existed) (f means forward)
    b                       back ot previous location (if existed) (b means backward)
    rm <path_alias>         remove path_alias
    activate                start record history in this session
    deactivate              stop reord history in this session
    show-graph              show history graph
    clear                   clean up history
    uninstall               udo init, deativate, self-uninstall, without cleanup history
Remark:
    path_alias cannot be any Commands, when using `j <path_alias>`
```


## Folder Structure
```
.
|-- .gitignore
|-- makefile
|-- src
|-- test
|-- build
|-- scripts
|-- dist
|-- pack.yaml
|-- README.md
```
- `.gitignore`: ignore `bulid`, `dist`
- `makefile`: all project wise command for devlopment.
- `src`: all script file
- `build`: all bulid artifects
- `scripts`: all scripts for development, mainly called my makefile
- `dist`: all distrution
- `pack.yaml`: package name, version and other metadata


## Architecture
everything written in shell script

## Scripts
- `bulid`: build the project, mainly clean up `dist` and copy necessary thing from `src` to `dist`
- `pack`: run build, then pack everything from dist to `build/releases/<package_name>_v<version>.tar.gz`
- `publish`: run build, pack, then use `gh release` to upload the file and `./script/install.sh`.
- `install`:
  -  if working dir is this project \(check `pack.yaml`\ match name and version), build and then install the package from dist to `~/.local/share` and link single entry to `~/.local/bin`. 
  -  if not, fetch from release git repo and unpack to somewhere in `/tmp/` install to ...
- `dev`: create a tmp `j-dev` in ~/.local/bin and link to `build/dev`, watch `src` file change and build to `build/dev` on save.  
