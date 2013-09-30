`/manual`
=========

_The Vijka manual_

A work in progress...


Languages
---------

For each language (in which the manual will be available) there should be a directory named with its [ISO 639 language code][gnu.iso639], optionally followed by a underscore and the [ISO 3166 two-letter country code][gnu.iso3166].

 * Brasil/Português: `/manual/pt_BR`
 * United States/English: `/manual/en_US` code:


Format
------

The manual is written in [Markdown][daring.md.h] for simplicity. It may however be ported to LaTeX in the future.

For a given language each chapter has its own directory, that should follow the example: `01-introduction`. Inside each of those there should be one or more Markdown files, and additional resources (such as images). 

Suggested editors for Markdown:

 * [Markable][]: online
 * [Dillinger][]: online
 * [ReText][]: Linux

[Dillinger]: http://dillinger.io
[gnu.iso639]: https://www.gnu.org/software/gettext/manual/html_node/Language-Codes.html#Language-Codes
[gnu.iso3166]: https://www.gnu.org/software/gettext/manual/html_node/Country-Codes.html#Country-Codes
[Markable]: http://markable.in/
[daring.md.h]: http://daringfireball.net/projects/markdown
[ReText]: https://sourceforge.net/projects/retext/
