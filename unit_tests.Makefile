all: neko cpp64 java

neko:
	haxe unit_tests.neko.hxml
	neko exp/unit_tests/neko/unit_tests.n
.PHONY: neko

cpp64:
	haxe unit_tests.cpp64.hxml
	exp/unit_tests/cpp/local64/Main
.PHONY: cpp64

java:
	haxe unit_tests.java.hxml
	java -jar exp/unit_tests/java/java.jar
.PHONY: java
