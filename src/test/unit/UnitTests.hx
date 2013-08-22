package test.unit;

import haxe.unit.TestRunner;

class UnitTests {
	var runner:TestRunner;

	public function new() {
		runner = new haxe.unit.TestRunner();
		
		// test custom assertions
		runner.add( new TestAssertion() );

		// test Haxe
		runner.add( new TestHaxe() );
		runner.add( new TestFloat() );
		
		// actual simulator tests
		runner.add( new TestUserCostModel() );
		runner.add( new TestNewDigraph() );
		// runner.add( new TestDigraph() );
	}

	public function run() {
		runner.run();
	}

	static function main() {
		var app = new UnitTests();
		app.run();
	}
}
