package test;

class TestHaxe extends TestCase {
	public function testMathPosInf() {
		assertTrue( 0. < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY < Math.POSITIVE_INFINITY );
	}

	public function testNullableInt() {
		var x = function ():Null<Int> {
			return null;
		}
		assertEquals( null, x() );
	}
}
