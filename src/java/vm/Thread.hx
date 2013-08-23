package java.vm;

#if java
@:native( "haxe.java.vm.Thread" )
class Thread implements java.lang.Runnable {

	private var __f:Void->Void;
	private var __mbox:List<Dynamic>;

	private function new( f ) {
		__f = f;
		__mbox = new List();
	}

	@:functionBody( "
		sincronized ( __mbox ) {
			__mbox.add( m );
			__mbox.notifyAll();
		}
	" )
	private function putMessage( m:Dynamic ):Void {}
	public function sendMessage( m:Dynamic ) putMessage( m );

	@:functionBody( "
		while ( true ) {
			sincronized ( __mbox ) {
				if ( block && __mbox.isEmpty() )
					__mbox.wait();
				else
					return __mbox.pop( m );
			}
		}
	" )
	private function getMessage( block:Bool ):Dynamic { return null; }


	private static var __main:Thread;
	// @:volatile
	private static var __index:haxe.ds.WeakMap<java.lang.Thread, Thread> = {
		var __i = new haxe.ds.WeakMap();
		__main = new Thread( null );
		__i.set( java.lang.Thread.currentThread(), __main );
		__i;
	};
	@:functionBody( "
		sincronized ( __index ) {
			__index.set( __t, t );
		}
	" )
	private static function __register( __t:java.lang.Thread, t:Thread ) {}
	@:functionBody( "
		sincronized ( __index ) {
			return __index.get( __t );
		}
	" )
	private static function __search( __t:java.lang.Thread ):Thread {
		return null;
	}

	public function run() {
		__f;
	}

	public static function create( f:Void->Void):Thread {
		var __t = new java.lang.Thread();
		var t = new Thread( f );
		__register( __t, t );
		return t;
	}

	public static function current():Thread {
		var t = __search( java.lang.Thread.currentThread() );
		if ( t == null ) throw "Failture to return current Haxe thread";
		return t;
	}

	public static function readMessage( block ):Dynamic {
		return current().getMessage( block );
	}

}
#end
