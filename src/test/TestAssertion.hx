package test;

class TestAssertion extends TestCase {
	
	public function testAssertInfinite() {
		assertPosInfinite( Math.POSITIVE_INFINITY );
		assertNegInfinite( Math.NEGATIVE_INFINITY );
	}

	public function testAssertNaN() {
		assertNaN( Math.NaN );
	}

}
