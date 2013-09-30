dox:
	mkdir -p doc/html
	haxe dox.xml.hxml
	haxe dox.html.hxml
.PHONY: dox

dox-clean:
	rm -rf doc/html
.PHONY: dox-clean
