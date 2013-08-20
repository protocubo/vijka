package graph.adjLists;

class PseudoArc extends Arc {
	
	public inline function new( v ) {
		super( v, v, null );
	}

}
