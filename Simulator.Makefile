Simulator: Simulator-neko Simulator-cpp Simulator-cpp64
.PHONY: Simulator

Simulator-neko:
	haxe ${HXFLAGS} Simulator.neko.hxml
Simulator-neko-run: Simulator-neko
	exp/Simulator/neko/Simulator
.PHONY: Simulator-neko Simulator-neko-run

Simulator-cpp:
	haxe ${HXFLAGS} Simulator.cpp.hxml
Simulator-cpp-run: Simulator-cpp
	exp/Simulator/cpp/Simulator
.PHONY: Simulator-cpp Simulator-cpp-run

Simulator-cpp64:
	haxe ${HXFLAGS} Simulator.cpp64.hxml
Simulator-cpp64-run: Simulator-cpp64
	exp/Simulator/cpp64/Simulator
.PHONY: Simulator-cpp64 Simulator-cpp64-run

Simulator-java:
	haxe ${HXFLAGS} Simulator.java.hxml
Simulator-java-run: Simulator-java
	java -jar exp/Simulator/java/Simulator.jar
.PHONY: Simulator-java Simulator-java-run
