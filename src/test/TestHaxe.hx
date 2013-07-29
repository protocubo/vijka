package test;

class TestHaxe extends TestCase {
	public function testMath() {
		assertTrue( 0. < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY < Math.POSITIVE_INFINITY );
	}
}
