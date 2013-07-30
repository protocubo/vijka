package test;

class Main {
	function new() {
		var runner = new haxe.unit.TestRunner();
		runner.add( new TestAssertion() );
		runner.add( new TestHaxe() );
		runner.add( new TestDigraph() );
		runner.run();
	}

	static function main() {
		var app = new Main();
	}
}
