package elebeta.ds.heap;

interface DAryHeapItem {

	/* 
	 * The predicate of a D-ary Heap dictates if it is a min or max heap, and
	 * also how comparissons are made; the `checkPredicate` function should be
	 * such that it returns `true` if `this` could appear before `b`.
	 * This is equivalent of returning `true` if `this` <= `b` on a min heap and
	 * `this` >= `b` on a max heap
	 */
	public function checkPredicate( b:DAryHeapItem ):Bool;

	/* 
	 * Method used by a DAryHeap for finding its position for this item
	 */
	public function getIndex( h:DAryHeap ):Int;

	/* 
	 * Method used by a DAryHeap for saving its position for this item
	 */
	public function saveIndex( h:DAryHeap, i:Int ):Void;

}
