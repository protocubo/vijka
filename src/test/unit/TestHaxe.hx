package test.unit;

class TestHaxe extends TestCase {
	
	// should fail on static targets with:
	//     On static platforms, null can't be used as basic type Int
	public function testNullComparison() {
		#if neko
		assertFalse(null == 0);
		assertFalse(null <= 0);
		assertFalse(null < 0);
		assertFalse(null >= 0);
		assertFalse(null > 0);
		assertTrue(null != 0);
		#end
	}

	#if ( !java || debug ) // testBugHaxeJava0001
	public function testNullableInt() {
		var x = function ():Null<Int> {
			return null;
		}
		assertEquals( null, x() );
	}
	#end



	#if java

	// reported: https://github.com/HaxeFoundation/haxe/issues/2048
	public function testBugHaxeJava0001() {
		var x = function ():Null<Int> {
			return null;
		}
		assertEquals( null, x() );
	}
	
	#end

}
