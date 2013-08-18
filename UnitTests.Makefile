UnitTests: UnitTests-neko-run UnitTests-cpp-run UnitTests-cpp64-run UnitTests-java-run

UnitTests-neko-run:
	haxe ${HXFLAGS} UnitTests.neko.hxml
	exp/UnitTests/neko/UnitTests
.PHONY: UnitTests-neko-run

UnitTests-cpp-run:
	haxe ${HXFLAGS} UnitTests.cpp.hxml
	exp/UnitTests/cpp/UnitTests
.PHONY: UnitTests-cpp-run

UnitTests-cpp64-run:
	haxe ${HXFLAGS} UnitTests.cpp64.hxml
	exp/UnitTests/cpp64/UnitTests
.PHONY: UnitTests-cpp64-run

UnitTests-java-run:
	haxe ${HXFLAGS} UnitTests.java.hxml
	java -jar exp/UnitTests/java/UnitTests.jar
.PHONY: UnitTests-java-run
