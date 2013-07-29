package graph.linkList;

import def.*;

class Vertex {

	public var node:Node;

	public var parent:Vertex;

	public var dist:Dist;
	public var time:Time;
	public var toll:Toll;
	public var cost:Cost;

	public var selectedToll:Bool;

	public function new( _node ) {
		node = _node;
	}

	public function clearState() {
		parent = null;
		selectedToll = false;

		dist = Math.POSITIVE_INFINITY;
		time = Math.POSITIVE_INFINITY;
		toll = Math.POSITIVE_INFINITY;
		cost = Math.POSITIVE_INFINITY;
	}

}
