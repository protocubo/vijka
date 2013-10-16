CHANGES
===


Head
---

Work in progress... Possible version v1.2.0.

 - Added some commands to manage the execution flow: `--stop` and `--sleep <seconds>`
 - Added this changelog (`CHANGES.md`)
 - Allow parenthesis on the unified query system
 - Better output (added identation and removed unnecessary information)
 - Crude and experimental macro system
 - ESRI Shapefile output (`--shp-*`)
 - Include more information about the build (commit, author, date)
 - Included haxe documentation generation via `dox`
 - Network compression (`--compress-network`)
 - Stop everything (`--restore`, `--execute-file`) on fatal errors
 - Verify and fix link shapes (`--fix-shapes`)
 - Changed/added commands:
    * Help: `--help [pattern]`
    * Macros: `--define <name><expansion>`, `--undefine <name>`, `--expand-file <path>` and `--show-macros`
    * Network manipulation: `--compress-network`, `--fix-shapes <coordinate tolerance>`
    * Timing: `--enable-timing` and `--disable-timing`
    * Other: `--stop`, `--sleep`


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
