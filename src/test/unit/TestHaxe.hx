package test.unit;

class TestHaxe extends TestCase {
	
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
