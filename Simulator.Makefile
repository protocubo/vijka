Simulator: Simulator-neko Simulator-cpp Simulator-cpp64 Simulator-java
.PHONY: Simulator

Simulator-neko: exp/Simulator/neko/Simulator
exp/Simulator/neko/Simulator:
	haxe ${HXFLAGS} Simulator.neko.hxml
Simulator-neko-run: exp/Simulator/neko/Simulator
	exp/Simulator/neko/Simulator
.PHONY: Simulator-neko Simulator-neko-run

Simulator-cpp: exp/Simulator/cpp/Simulator
exp/Simulator/cpp/Simulator:
	haxe ${HXFLAGS} Simulator.cpp.hxml
Simulator-cpp-run: exp/Simulator/cpp/Simulator
	exp/Simulator/cpp/Simulator
.PHONY: Simulator-cpp Simulator-cpp-run

Simulator-cpp64: exp/Simulator/cpp64/Simulator
exp/Simulator/cpp64/Simulator:
	haxe ${HXFLAGS} Simulator.cpp64.hxml
Simulator-cpp64-run: exp/Simulator/cpp64/Simulator
	exp/Simulator/cpp64/Simulator
.PHONY: Simulator-cpp64 Simulator-cpp64-run

Simulator-java: exp/Simulator/java/Simulator.jar
exp/Simulator/java/Simulator.jar:
	haxe ${HXFLAGS} Simulator.java.hxml
Simulator-java-run: exp/Simulator/java/Simulator.jar
	java -jar exp/Simulator/java/Simulator.jar
.PHONY: Simulator-java Simulator-java-run
