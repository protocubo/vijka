package test;

import haxe.PosInfos;

class TestCase extends haxe.unit.TestCase {

	function assertException( expected:Dynamic, func:Void->Void, ?c:PosInfos ) {
		currentTest.done = true;
		try {
			func();
			throw "no_exception";
		}
		catch ( actual:Dynamic ) {
			if ( actual != expected ) {
				currentTest.success = false;
				currentTest.error   = "expected '" + expected + "' but was '" + actual + "'";
				currentTest.posInfos = c;
				throw currentTest;
			}
		}
	}

	function assertAnyException( func:Void->Void, ?c:PosInfos ) {
		currentTest.done = true;
		try {
			func();
			throw "no_exception";
		}
		catch ( actual:Dynamic ) {
			if ( Std.is( actual, String ) && actual == "no_exception" ) {
				currentTest.success = false;
				currentTest.error   = "expected a exception";
				currentTest.posInfos = c;
				throw currentTest;
			}
		}
	}

	function assertEqualArrays<T>( expected:Array<T>, value:Array<T> ) {
		assertEquals( expected.toString(), value.toString() );
	}

	function assertPosInfinite( value:Float, ?c:PosInfos ) {
		currentTest.done = true;
		if ( Math.isNaN( value ) || Math.isFinite( value ) || value < 0. ) {
			currentTest.success = false;
			currentTest.error   = "expected 'Math.POSITIVE_INFINITY' but was '" + value + "'";
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function assertNegInfinite( value:Float, ?c:PosInfos ) {
		currentTest.done = true;
		if ( Math.isNaN( value ) || Math.isFinite( value ) || value > 0. ) {
			currentTest.success = false;
			currentTest.error   = "expected 'Math.NEGATIVE_INFINITY' but was '" + value + "'";
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function assertNaN( value:Float, ?c:PosInfos ) {
		currentTest.done = true;
		if ( !Math.isNaN( value ) ) {
			currentTest.success = false;
			currentTest.error   = "expected 'Math.NaN' but was '" + value + "'";
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

}
