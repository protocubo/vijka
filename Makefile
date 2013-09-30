#
# Vijka GNU Makefile
#
# Eases building Vijka, running unit tests and generating Haxe dox
#
# Each target can also be build using the hxml files in `mk/`
#

# Vijka ----------------------------------------------------------------------------------------------------------------

vijka: vijka-java
vijka-all: vijka-java vijka-cpp64 vijka-cpp vijka-neko
vijka-java:
	haxe ${HXFLAGS} mk/vijka.java.hxml
vijka-java-run: vijka-java
	java -jar ${JAVAFLAGS} exp/vijka/java/vijka.jar ${ARGS}
vijka-cpp64:
	haxe ${HXFLAGS} mk/vijka.cpp64.hxml
vijka-cpp64-run: vijka-cpp64
	exp/vijka/cpp64/vijka ${ARGS}
vijka-cpp:
	haxe ${HXFLAGS} mk/vijka.cpp.hxml
vijka-cpp-run: vijka-cpp
	exp/vijka/cpp/vijka ${ARGS}
vijka-neko:
	haxe ${HXFLAGS} mk/vijka.neko.hxml
vijka-neko-run: vijka-neko
	exp/vijka/neko/vijka ${ARGS}
.PHONY: vijka vijka-java vijka-java-run vijka-cpp64 vijka-cpp64-run vijka-cpp vijka-cpp-run vijka-neko vijka-neko-run


# Unit testing ---------------------------------------------------------------------------------------------------------

UnitTests-all: UnitTests-java-run UnitTests-cpp64-run UnitTests-cpp-run UnitTests-neko-run
UnitTests-java-run:
	haxe ${HXFLAGS} mk/UnitTests.java.hxml
	java -jar exp/UnitTests/java/UnitTests.jar
UnitTests-cpp64-run:
	haxe ${HXFLAGS} mk/UnitTests.cpp64.hxml
	exp/UnitTests/cpp64/UnitTests
UnitTests-cpp-run:
	haxe ${HXFLAGS} mk/UnitTests.cpp.hxml
	exp/UnitTests/cpp/UnitTests
UnitTests-neko-run:
	haxe ${HXFLAGS} mk/UnitTests.neko.hxml
	exp/UnitTests/neko/UnitTests
.PHONY: UnitTests UnitTests-java-run UnitTests-cpp64-run UnitTests-cpp-run UnitTests-neko-run


# Haxe dox -------------------------------------------------------------------------------------------------------------

xml:
	haxe mk/dox.xml.hxml
.PHONY: xml

ifndef DOX_ROOT
# DOX_ROOT defaults to local path
DOX_ROOT=${PWD}/doc/html
endif

dox:
	mkdir -p doc/html
	haxelib run dox -r ${DOX_ROOT} -o doc/html -i doc/xml -t doc/templates
dox-clean:
	rm -rf doc/html
.PHONY: dox dox-clean


# Auxiliary ------------------------------------------------------------------------------------------------------------

all.hxml:
	mk/all.hxml.sh
.PHONY: all.hxml
