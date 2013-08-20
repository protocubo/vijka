package elebeta.ds.heap;

class BinaryHeap extends DAryHeap {
	
	public function new( ?reserve=DAryHeap.DEFAULT_RESERVE ) {
		super( 2, reserve );
	}
	
}
