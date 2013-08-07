all: neko cpp64 java

neko:
	haxe compile_sim.neko.hxml
	neko exp/compile_sim/neko/compile_sim.n
.PHONY: neko

cpp64:
	haxe compile_sim.cpp64.hxml
	exp/compile_sim/cpp/local64/CompileSim
.PHONY: cpp64

java:
	haxe compile_sim.java.hxml
	java -jar exp/compile_sim/java/java.jar
.PHONY: java
