package test.unit;

class UnitTests {
	function new() {
		var runner = new haxe.unit.TestRunner();
		
		// test custom assertions
		runner.add( new TestAssertion() );

		// test Haxe
		runner.add( new TestHaxe() );
		runner.add( new TestFloat() );
		
		// actual simulator tests
		runner.add( new TestUserCostModel() );
		runner.add( new TestDigraph() );
		
		runner.run();
	}

	static function main() {
		var app = new UnitTests();
	}
}
