package test.unit;

class TestFloat extends TestCase {
	public function testPosInf() {
		// In comparison operations, positive infinity is larger than all values except itself and NaN
		// (http://www.gnu.org/software/libc/manual/html_node/Infinity-and-NaN.html)
		// comparissn with zero
		assertTrue( 0. < Math.POSITIVE_INFINITY );
		assertTrue( Math.POSITIVE_INFINITY > 0. );
		// comparissn with itself
		assertFalse( Math.POSITIVE_INFINITY < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY > Math.POSITIVE_INFINITY );
		// comparison with NaN
		assertFalse( Math.NaN < Math.POSITIVE_INFINITY );
		#if ( !neko || debug ) // testBugHaxeNeko0001
		assertFalse( Math.POSITIVE_INFINITY > Math.NaN );
		#end
		// more complex comparisons with itself
		assertFalse( Math.POSITIVE_INFINITY - 1. < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY > Math.POSITIVE_INFINITY - 1. );
		assertFalse( Math.POSITIVE_INFINITY/2. < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY > Math.POSITIVE_INFINITY/2. );
		assertFalse( Math.POSITIVE_INFINITY/2. < Math.POSITIVE_INFINITY );
		assertFalse( Math.POSITIVE_INFINITY > Math.POSITIVE_INFINITY/2. );
	}

	public function testIdeterminateInfTimesZero() {
		// 0 * +-oo = NaN
		// (http://en.wikipedia.org/wiki/Indeterminate_forms)
		assertNaN( 0.*Math.POSITIVE_INFINITY );
		assertNaN( Math.POSITIVE_INFINITY*0. );
	}

	#if !neko // testBugHaxeNeko0002
	public function testFloatIntegers() {
		var i:Int = 65535;
		var f:Float = 65535;
		#if !python
		assertFalse( i*i > 0 );  // expects an overflow
		#end
		assertTrue( f*f > 0 );
	}
	#end



	#if neko
	
	// related to: https://code.google.com/p/nekovm/issues/detail?id=37
	// related to: https://code.google.com/p/nekovm/issues/detail?id=38
	// related to: https://github.com/HaxeFoundation/neko/pull/2
	public function testBugHaxeNeko0001() {
		assertFalse( Math.POSITIVE_INFINITY > Math.NaN );
	}

	// reported: https://github.com/HaxeFoundation/haxe/issues/1282
	public function testBugHaxeNeko0002() {
		var i:Int = 65535;
		var f:Float = 65535;
		assertFalse( i*i > 0 );
		assertTrue( f*f > 0 );
	}
	
	#end
	
}
