all: neko cpp64

neko:
	haxe compile_sim.neko.hxml
run-neko: neko
	exp/compile_sim/neko/CompileSim
.PHONY: neko run-neko

cpp64:
	haxe compile_sim.cpp64.hxml --no-inline
run-cpp64: cpp64
	exp/compile_sim/cpp/local64/CompileSim
.PHONY: cpp64 run-cpp64

java:
	haxe compile_sim.java.hxml
run-java: java
	java -jar exp/compile_sim/java/java.jar
.PHONY: java run-java
