## rename show-graph to history
```
show to history of cd
Usage:
    j history [flag]
Flags:
    -g, --graph show-graph
```
## should record "graph" instead of "linear history"
let me explain by scenario:
```
/home/username$ cd projects
/home/username/projects$ j projects .
/home/username/projects$ cd ..
/home/username$ cd projects
/home/username/projects$ cd /tmp/tmp
/tmp/tmp$ j b
/home/username/projects$ j b
/home/username$ cd somewhere
/home/username/somewhere$ j somewhere .
/home/username/somewhere$ j history -g
```
should print
```
* /home/username
* /home/username/projects (projects)
* /home/username
|\
| * /home/username/projects
| * /tmp/tmp
* /home/username/somewhere (HEAD -> somewhere)
```
## normal history display
```
* /home/username
* /home/username/projects (projects)
* /home/username
* /home/username/somewhere (HEAD -> somewhere)
```
## the graph display should be git log --graph like
the spec is here:
each cd create a node (*)
each j b or j f only move HEAD, no node creation
the color of `*` should be normal
the color of edge `|` should cycle in `red`, `yellow`, `blue`, `green`, `purple`, `cyan`
the color of path should be yellow
the color of alias should be green
the color of `HEAD` should be blue, as well as the arrow of `HEAD ->` if HEAD is in an alias
when j deacitvate, show everything in gray, and show a indication message it's deactive now
## add a help command and rewrite everything
Commands:
    help                    show help
    jump                    cd to the path of alias_name. See Remark.
    create                  save path as alias_name (session-scoped by default)
    ls                      list all aliases
    rm                      remove alias(es)
    f                       go to next location (if existed)
    b                       back to previous location (if existed)
    show-graph              show history graph
    clear                   clean up history
    init                    modify shell rc file, hijack cd to record history
    deinit                  undo init
    activate                start recording history in this session
    deactivate              stop recording history in this session
    uninstall               undo init, self-uninstall, keep alias/history data

this should be rewrite, I just create a hint to you, you should rewrite it better
and I remove all the inline usage of command, to know more about how to use a command, use `help COMMAND`

## `j -g <alias_name>`
this spcial command will turn \<alias_name\> to global. should write in it's own usage in the main usage messaeg and it's the shortcut of `j create -g <alias_name>`

## Trivia
remeber to `gh repo create ...`, git add . && git commit .., && git push