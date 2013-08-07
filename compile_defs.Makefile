all: neko

neko:
	haxe compile_defs.neko.hxml
	neko exp/compile_defs/neko/compile_defs.n
.PHONY: neko
