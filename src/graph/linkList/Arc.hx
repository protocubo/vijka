package graph.linkList;

import def.*;

@:allow( graph.linkList.Digraph )
class Arc {

	// entity
	public var link( default, null ):Link;
	
	// relation
	public var from( default, null ):Vertex;
	public var to( default, null ):Vertex;

	function new( _from, _to, _link ) {
		link = _link;
		from = _from;
		to = _to;
	}

	public function isPseudo() {
		return from == to && link == null;
	}

}
