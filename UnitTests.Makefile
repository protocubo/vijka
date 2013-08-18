UnitTests: UnitTests-neko-run UnitTests-cpp-run UnitTests-cpp64-run UnitTests-java-run
.PHONY: UnitTests

exp/UnitTests/neko/UnitTests:
	haxe ${HXFLAGS} UnitTests.neko.hxml
UnitTests-neko-run: exp/UnitTests/neko/UnitTests
	exp/UnitTests/neko/UnitTests
.PHONY: UnitTests-neko-run

exp/UnitTests/cpp/UnitTests:
	haxe ${HXFLAGS} UnitTests.cpp.hxml
UnitTests-cpp-run: exp/UnitTests/cpp/UnitTests
	exp/UnitTests/cpp/UnitTests
.PHONY: UnitTests-cpp-run

exp/UnitTests/cpp64/UnitTests:
	haxe ${HXFLAGS} UnitTests.cpp64.hxml
UnitTests-cpp64-run: exp/UnitTests/cpp64/UnitTests
	exp/UnitTests/cpp64/UnitTests
.PHONY: UnitTests-cpp64-run

java -jar exp/UnitTests/java/UnitTests.jar:
	haxe ${HXFLAGS} UnitTests.java.hxml
UnitTests-java-run: exp/UnitTests/java/UnitTests.jar
	java -jar exp/UnitTests/java/UnitTests.jar
.PHONY: UnitTests-java-run
