package graph.adjLists;

import def.*;
import elebeta.ds.heap.DAryHeap;
import elebeta.ds.heap.DAryHeapItem;

class Vertex implements DAryHeapItem<Vertex> {

	public var self( get, never ):Vertex;
	private inline function get_self():Vertex return this;

	// entity
	public var node( default, null ):Node;

	// path storage
	public var parent( default, null ):Arc;

	// cost storage
	public var dist( default, null ):Dist;
	public var time( default, null ):Time;
	public var toll( default, null ):Toll;
	public var cost( default, null ):Cost;

	// relation
	public var adjs:Array<Arc>;

	public inline function new( _node ) {
		node = _node;
		adjs = [];
	}

	public inline function clearPath() {
		parent = null;
	}

	public inline function clearCosts() {
		dist = Math.POSITIVE_INFINITY;
		time = Math.POSITIVE_INFINITY;
		toll = Math.POSITIVE_INFINITY;
		cost = Math.POSITIVE_INFINITY;
	}

	public inline function clearState() {
		clearPath();
		clearCosts();
	}


	// QUEUE --------------------------------------------------------------------

	public var est( default, null ):Float; // cost + ?heuristic
	public var index( default, null ):Int;

	public inline function checkPredicate( b:DAryHeapItem<Vertex> ):Bool {
		return est < b.self.est;
	}

	public inline function getIndex( h:DAryHeap<Vertex> ):Int {
		return index;
	}

	public inline function saveIndex( h:DAryHeap<Vertex>, i:Int ):Void {
		index = i;
	}

}
