package graph.linkList;

@:allow( graph.linkList.Digraph )
class PseudoArc extends Arc {
	
	function new( v ) {
		super( v, v, null );
	}

}
