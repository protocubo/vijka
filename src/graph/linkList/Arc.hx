package graph.linkList;

import def.*;

class Arc {

	// entity
	public var link:Link;
	
	// relation
	public var from:Vertex;
	public var to:Vertex;

	public function new( _from, _to, _link ) {
		link = _link;
		from = _from;
		to = _to;
	}

}
