Simulator: Simulator-neko Simulator-cpp64

Simulator-neko:
	haxe ${HXFLAGS} Simulator.neko.hxml
Simulator-neko-run: Simulator-neko
	exp/Simulator/neko/Simulator

Simulator-cpp64:
	haxe ${HXFLAGS} Simulator.cpp64.hxml
Simulator-cpp64-run: Simulator-cpp64
	exp/Simulator/cpp64/Simulator

Simulator-java:
	haxe ${HXFLAGS} Simulator.java.hxml
Simulator-java-run: Simulator-java
	java -jar exp/Simulator/java/Simulator.jar

