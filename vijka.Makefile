vijka: vijka-java vijka-cpp64 vijka-cpp vijka-neko
.PHONY: vijka

vijka-java:
	haxe ${HXFLAGS} vijka.java.hxml
vijka-java-run: vijka-java
	java -jar ${JAVAFLAGS} exp/vijka/java/vijka.jar ${ARGS}
.PHONY: vijka-java vijka-java-run

vijka-cpp64:
	haxe ${HXFLAGS} vijka.cpp64.hxml
vijka-cpp64-run: vijka-cpp64
	exp/vijka/cpp64/vijka ${ARGS}
.PHONY: vijka-cpp64 vijka-cpp64-run

vijka-cpp:
	haxe ${HXFLAGS} vijka.cpp.hxml
vijka-cpp-run: vijka-cpp
	exp/vijka/cpp/vijka ${ARGS}
.PHONY: vijka-cpp vijka-cpp-run

vijka-neko:
	haxe ${HXFLAGS} vijka.neko.hxml
vijka-neko-run: vijka-neko
	exp/vijka/neko/vijka ${ARGS}
.PHONY: vijka-neko vijka-neko-run

