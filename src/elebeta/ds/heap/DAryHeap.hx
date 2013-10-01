/**
	D-ary heap base class
**/

package elebeta.ds.heap;

/**
	Underlying container
**/
private typedef Underlying<I> = Array<I>;

/**
	A generic base for building D-ary heaps

	D-ary heaps are used for implementing priority queues. This is just a base class, predicate and element index
	get/set methods should be implemented in a subclass.
**/
@:generic
class DAryHeap<Item> implements elebeta.queue.Queue<Item> {
	
	public var arity(default,null):Int;
	public var length(default,null):Int;
	public var capacity(get,never):Int;

	private var h:Underlying<Item>; // [ 1, 11, 12, 13, 14, 111, 112, 113, 114, 121, 122, 123, 124, ... ]


	// CONSTRUCTION ----------------------------------------------------------------------------------------------------

	private function new( _arity, _reserve ) {
		if ( _arity < 2 )
			throw "D-ary heap are only possible for D >= 2";
		arity = _arity;
		length = 0;
		if ( _reserve >= 0 )
			h = emptyUrderlying( _reserve );
	}


	// NOT IMPLEMENTED METHODS -----------------------------------------------------------------------------------------

	/**
		[NOT IMPLEMENTED] Checks if the predicate holds for elements `a` and `b`, in that order

		The predicate of a D-ary Heap dictates if it is a min or a max heap, and also how comparissons are made.
		`checkPredicate` should return `true` if `a` could appear before `b`. This is equivalent of returning `true`
		if `a` <= `b` on a min heap and `a` >= `b` on a max heap
	**/
	public function checkPredicate( a:Item, b:Item ):Bool { throw "checkPredicate not implemented"; }
	
	/**
		[NOT IMPLEMENTED] Returns the internal index of an `item`; used for quickly finding `item` in the heap
	**/
	public function getIndex( item:Item ):Int { throw "getIndex not implemented"; }

	/**
		[NOT IMPLEMENTED] Sets the internal index of an `item`; later, `getIndex` can be used to retrieve this
		information and allow quick access for the `item`
	**/
	public function saveIndex( item:Item, pos:Int ):Void { throw "saveIndex not implemented"; }

	public function clearIndex( item:Item ):Void { throw "clearIndex not implemented"; }

	public function contains( item:Item ):Bool { throw "contains not implemented"; }


	// QUEUING API -----------------------------------------------------------------------------------------------------

	/**
		Checks if the heap is empty
	**/
	public inline function isEmpty():Bool return length == 0;

	/**
		Checks if the heap is _not_ empty
	**/
	public inline function notEmpty():Bool return length > 0;

	/**
		Adds a new `item` to the heap
	**/
	public function add( item:Item ):Void {
		if ( contains( item ) )
			throw "Cannot add an item already in the heap";
		insert( length, item );
		fix_up( length++ );
	}

	/**
		Peeks at the next element to be extracted from the heap
	**/
	public inline function first():Null<Item> {
		return notEmpty() ? hget( 0 ) : null;
	}

	/**
		Extracts and returns the next element from the heap
	**/
	public function pop():Null<Item> {
		if ( notEmpty() ) {
			exchange( 0, --length );
			fix_down( 0 );
			var r = hext( length );
			clearIndex( r );
			return r;
		}
		else
			return null;
	}

	/**
		Updates the position of `item` in the heap/queue
	**/
	public function update( item:Item ):Void {
		var i = getIndex( item );
		fix_up( i );
		fix_down( i );
	}

	/**
		Clears the heap
	**/
	public function clear():Void {
		length = 0;
	}


	// INSPECTION API -----------------------------------------------------------

	public function dumpUnderlying():Iterable<Item> {
		return h.copy(); // only because underlying is Array
	}


	// PROPERTIES ---------------------------------------------------------------

	private function get_capacity() return h != null ? h.length : 0;


	// INTERNALS ----------------------------------------------------------------

	private inline function heapify() {
		var s = parent( length - 1 );
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
