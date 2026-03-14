# Eason Jump
A CLI tool `j` for fast directory jumping with path aliases and session history.
![alt text](public/demo-1.gif)
## Prerequiste
It's good to go if your shell is **Bash**, **Zsh** or **Fish**
## Install
```sh
curl -fsSL https://github.com/s7887177/eason-jump/releases/latest/download/install.sh | sh
```

## Usage

```
Usage:
  j COMMAND
Aliases:
  j <alias>               alias of `j jump <alias>`, jump to alias 
  j [-g] <alias> <path>   alias of `j create [-g] <alias> <path>`, create alias
  j -g <alias>            alias of `j create -g <alias>`, globalize session alias

eason-jump — quick directory navigation with aliases and `cd` history

Alias Commands:
  create               create alias, or promote session alias to global
  ls                   list all aliases
  rm                   remove an alias
  jump                 change directory to the path of alias

History Command:
  f                    go forward in history
  b                    go backward in history
  history              show history
  clear                clear history

Lifecycle Commands:
  init                 set up shell integration
  deinit               remove shell integration
  activate             start recording history
  deactivate           stop recording history
  uninstall            remove eason-jump (keeps data)

Other Commands:
  help [COMMAND]       show help, or detailed help for COMMAND
```