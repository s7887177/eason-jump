# Eason Jump

A CLI tool `j` for fast directory jumping with path aliases and session history.

## Install

```sh
# From source (in the project directory):
make install

# From release:
curl -fsSL https://github.com/s7887177/eason-jump/releases/latest/download/install.sh | sh
```

## Usage

```
Usage:
    j COMMAND
    j <path_alias>          cd to the path of path_alias
    j <path_alias> <path>   save path as path_alias

Commands:
    init                    modify shell rc file, hijack cd to record history
    deinit                  undo init, deactivate
    ls                      list all alias
    f                       go to next location (if existed) (f means forward)
    b                       back to previous location (if existed) (b means backward)
    rm <path_alias>         remove path_alias
    activate                start record history in this session
    deactivate              stop record history in this session
    show-graph              show history graph
    clear                   clean up history
    uninstall               undo init, deactivate, self-uninstall, without cleanup history

Remark:
    path_alias cannot be any command name when using j <path_alias>
```

## Supported Shells

- Bash
- Zsh
- Fish
