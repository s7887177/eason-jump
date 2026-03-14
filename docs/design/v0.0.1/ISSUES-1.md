This issue has been solved mostly, if you are an ai agent, DO NOT READ IT

### `install.sh` shouldn't rely on `gh` (it's not push yet, check later)
the `install.sh` will be publish to github release, the user will install it via `curl ... | sh`. we should not rely on gh.
just bake the url to fetch. the repo is at https://github.com/s7887177/eason-jump/
### j ls display format (fix)
do not display `alias_name=path` it's ugly
let's display table like: with minimal tabs between alias... but align every column,
```
alias_1             /home/eason/...
alias_2_is_longer   /asfdsfasfaf/dsafaf...
```
### j activation
eason@MSI:~/projects/eason-jump$ j activate
Run 'j activate' in your shell (not as a script).
eason@MSI:~/projects/eason-jump$ j deactivate
Run 'j deactivate' in your shell (not as a script).
### It didn't record history after cd
eason@MSI:~/projects/eason-jump$ cd ..
eason@MSI:~/projects$ j b
no history
eason@MSI:~/projects$ j show-graph
(no history)

## new features
### global alias
```
Usage:
    j COMMAND
    j <alias_name>                      an alias of `j jump <alias_name>`
    j [flag] <alias_name> <path_name>   an alias of `j create <alias_name> <path>`
COMMANDS:
    j jump <alias_name>             ...(a short description), See Remark
    j create <alias_name> <path>    ...(a short description), See Remark
Flags:
    -g  record the alias globally
Remark:
    It's possible to record a global alias and session alias with the same name, but the recording orders matter.
    if record session alias first, and then global, it will remove the session alias and create a global alias with that name.
    If record global alias first, and then session, it will create a session alias without touch the global.
    and the resolving order will be. session > global, when using `j <alias_name>` to jump to path. 
```
### show alias type
`j ls` should show alias type in a column

## Trivia
- make the Usage message better
- after finish everything, create the repo and upload use `gh`, `make release`

