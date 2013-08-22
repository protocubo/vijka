package graph.adjLists;

@:access( graph.adjLists.Vertex )
class Queue extends elebeta.ds.heap.DAryHeap<Vertex> {

	public function new( arity, reserve ) {
		super( arity, reserve );
	}

	public function has( a:Vertex ) {
		var i = getIndex( a );
		return i >= 0 && i < length && h[i] == a;
	}

	/* 
	 * The predicate of a D-ary Heap dictates if it is a min or max heap, and
	 * also how comparissons are made; the `checkPredicate` function should be
	 * such that it returns `true` if `a` could appear before `b`.
	 * This is equivalent of returning `true` if `a` <= `b` on a min heap and
	 * `a` >= `b` on a max heap
	 */
	override inline function checkPredicate( a:Vertex, b:Vertex ):Bool {
		return a.est <= b.est;
	}
	
	/* 
	 * Method used by a DAryHeap for finding its position for this item
	 */
	override inline function getIndex( e:Vertex ):Int {
		return e.index;
	}

	/* 
	 * Method used by a DAryHeap for saving its position for this item
	 */
	override inline function saveIndex( e:Vertex, i:Int ):Void {
		e.index = i;
	}

}