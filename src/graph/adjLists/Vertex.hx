package graph.adjLists;

import def.*;

class Vertex {

	// entity
	public var node( default, null ):Node;

	// path storage
	public var parent( default, null ):Arc;

	// cost storage
	public var dist( default, null ):Dist;
	public var time( default, null ):Time;
	public var toll( default, null ):Toll;
	public var cost( default, null ):Cost;

	// run label
	public var label:Label;

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
		label = null;
		clearPath();
		clearCosts();
	}


	// QUEUE --------------------------------------------------------------------

	public var est( default, null ):Float; // cost + ?heuristic
	public var index( default, null ):Int;

}
