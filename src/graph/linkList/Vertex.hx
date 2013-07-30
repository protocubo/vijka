package graph.linkList;

import def.*;

@:allow( graph.linkList.Digraph )
class Vertex {

	public var node( default, null ):Node;

	public var parent( default, null ):Arc;

	public var dist( default, null ):Dist;
	public var time( default, null ):Time;
	public var toll( default, null ):Toll;
	public var cost( default, null ):Cost;

	public var selectedToll( default, null ):Bool;

	function new( _node ) {
		node = _node;
	}

	inline function clearState() {
		parent = null;
		selectedToll = false;

		dist = Math.POSITIVE_INFINITY;
		time = Math.POSITIVE_INFINITY;
		toll = Math.POSITIVE_INFINITY;
		cost = Math.POSITIVE_INFINITY;
	}

}
