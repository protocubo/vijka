CHANGES
===


Head
---

Work in progress... Possible version v1.2.0.

 - Added this changelog (`CHANGES.md`)
 - Allow breaking in `--restore` and `--execute-file` (via `--stop`)
 - Allow parenthesis on the unified query system
 - Better output (added identation and removed unnecessary information)
 - Crude and experimental macro system
 - Include more information about the build (commit, author, date)
 - Included haxe documentation generation via `dox`
 - Stop everything (`--restore`, `--execute-file`) on fatal errors
 - Changed/added commands:
    * Macros: `--define <name><expansion>`, `--undefine <name>`, `--expand-file <path>` and `--show-macros`
    * Timing: `--enable-timing` and `--disable-timing`
    * Help: `--help [pattern]`
    * Other: `--stop`


v1.1.1
---

Fixes some problems for Windows users.

 - Fixes newline problems on Windows for command logs generated on Linux.


v1.1.0
---

First open source release.


v1.0.0-consult-alamak
---

Internal version.
