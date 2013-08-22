package elebeta.ds.heap;

private typedef Underlying<I> = Array<I>;

@:generic
class DAryHeap<Item> {
	
	public var arity(default,null):Int;
	public var length(default,null):Int;
	public var capacity(get,never):Int;

	private var h:Underlying<Item>; // [ 1, 11, 12, 13, 14, 111, 112, 113, 114, 121, 122, 123, 124, ... ]


	// CONSTRUCTION -------------------------------------------------------------

	private function new( _arity, _reserve ) {
		if ( _arity < 2 )
			throw "D-ary heap are only possible for D >= 2";
		arity = _arity;
		length = 0;
		if ( _reserve >= 0 )
			h = emptyUrderlying( _reserve );
	}


	// NOT IMPLEMENTED METHODS --------------------------------------------------

	/* 
	 * The predicate of a D-ary Heap dictates if it is a min or max heap, and
	 * also how comparissons are made; the `checkPredicate` function should be
	 * such that it returns `true` if `a` could appear before `b`.
	 * This is equivalent of returning `true` if `a` <= `b` on a min heap and
	 * `a` >= `b` on a max heap
	 */
	function checkPredicate( a:Item, b:Item ):Bool { throw "checkPredicate not implemented"; }
	
	/* 
	 * Method used by a DAryHeap for finding its position for this item
	 */
	function getIndex( e:Item ):Int { throw "getIndex not implemented"; }

	/* 
	 * Method used by a DAryHeap for saving its position for this item
	 */
	function saveIndex( e:Item, i:Int ):Void { throw "saveIndex not implemented"; }


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
		var i = getIndex( e );
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
			saveIndex( h[i], i );
		while ( 0 <= s )
			fix_down( s-- );
	}

	private inline function fix_up( i:Int ):Void {
		var j;
		while ( 0 < i && !checkPredicate( h[j=parent(i)], h[i] ) ) {
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
				if ( checkPredicate( h[k], h[j] ) )
					j = k;
				a++;
			}
			if ( checkPredicate( h[i], h[j] ) )
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
		saveIndex( e, i );
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
	private inline function floor( f:Float ) return Std.int( f );

	private function emptyUrderlying( reserve ) {
		var a = [];
		if ( reserve > 0 )
			a[reserve - 1] = null;
		return a;
	}

	private function underlying<Item>( it:Iterable<Item> ) {
		return Lambda.array( it );
	}

}
