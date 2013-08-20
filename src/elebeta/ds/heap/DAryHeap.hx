package elebeta.ds.heap;

private typedef Underlying<T> = Array<T>;
private typedef Item = elebeta.ds.heap.DAryHeapItem;

class DAryHeap {

	public inline static var DEFAULT_ARITY = 4;
	public inline static var DEFAULT_RESERVE = 32;

	public var arity(default,null):Int;
	public var length(default,null):Int;
	public var capacity(get,never):Int;

	private var h:Underlying<Item>; // [ 1, 11, 12, 13, 14, 111, 112, 113, 114, 121, 122, 123, 124, ... ]


	// CONSTRUCTION -------------------------------------------------------------

	public function new( ?_arity=DEFAULT_ARITY, ?_reserve=DEFAULT_RESERVE ) {
		if ( arity < 2 )
			throw "D-ary heap are only possible for D >= 2";
		arity = _arity;
		length = 0;
		if ( _reserve >= 0 )
			h = emptyUrderlying( _reserve );
	}

	public static function build( it:Iterable<Item>, ?_arity=DEFAULT_ARITY ) {
		var heap = new DAryHeap( _arity, -1 );
		heap.h = underlying( it );
		heap.length = heap.h.length;
		heap.heapify();
		return heap;
	}


	// QUEUING API --------------------------------------------------------------

	public inline function isEmpty():Bool return length == 0;

	public inline function notEmpty():Bool return length > 0;

	public inline function put( e:Item ):Void {
		insert( length, e );
		fix_up( length++ );
	}

	public inline function extract():Null<Item> {
		if ( notEmpty() ) {
			exchange( 0, --length );
			fix_down( 0 );
			return hext( length );
		}
		else
			return null;
	}

	public inline function peek():Null<Item> {
		return notEmpty() ? hget( 0 ) : null;
	}

	public inline function update( e:Item ):Void {
		var i = e.getIndex( this );
		fix_up( i );
		fix_down( i );
	}


	// INSPECTION API -----------------------------------------------------------

	public function dumpUnderlying():Iterable<Item> {
		return h.copy(); // only because underlying is Array
	}


	// PROPERTIES ---------------------------------------------------------------

	private function get_capacity() return h != null ? h.length : 0;


	// INTERNALS ----------------------------------------------------------------

	private inline function heapify() {
		var s = floor( parent( length - 1 ) );
		for ( i in 0...length )
			h[i].saveIndex( this, i );
		while ( 0 <= s )
			fix_down( s-- );
	}

	private inline function fix_up( i:Int ):Void {
		var j;
		while ( 0 < i && !h[ j=parent(i) ].checkPredicate( h[i] ) ) {
			exchange( i, j );
			i = j;
		}
	}

	private inline function fix_down( i:Int ):Void {
		var j;
		while ( length > ( j = child( i, 1 ) ) ) {
			var a = 2;
			var k;
			while ( arity >= a && length > ( k = child( i, a ) ) ) {
				if ( h[k].checkPredicate( h[j] ) )
					j = k;
				a++;
			}
			if ( h[i].checkPredicate( h[j] ) )
				break;
			exchange( i, j );
			i = j;
		}
	}

	private inline function exchange( i:Int, j:Int ):Void {
		var t = h[i];
		insert( i, h[j] );
		insert( j, t );
	}

	private inline function insert( i:Int, e:Item ):Void {
		hset( i, e );
		e.saveIndex( this, i );
	}

	// 1 <= n <= arity
	private inline function child( i:Int, n:Int ):Int {
		return arity*i + n;
	}
	
	private inline function parent( i:Int ):Int {
		return floor( ( i - 1 )/arity );
	}


	// HELPERS ------------------------------------------------------------------

	// these will be important if underlying changes to haxe.ds.Vector
	// later these may also be abstracted
	private inline function hget( i:Int ):Item return h[i];
	private inline function hext( i:Int ):Item return h[i];
	private inline function hset( i:Int, e:Item ):Item return h[i] = e;

	// fast floor
	// `Std.int` should be faster than `Math.floor`, although it only makes sense
	// for positive `f`
	private static inline function floor( f:Float ) return Std.int( f );

	private static function emptyUrderlying( reserve ) {
		var a = [];
		if ( reserve > 0 )
			a[reserve - 1] = null;
		return a;
	}

	private static function underlying( it:Iterable<Item> ) {
		return Lambda.array( it );
	}

}
