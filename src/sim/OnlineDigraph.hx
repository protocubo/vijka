package sim;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class OnlineDigraph {

	private var dg:graph.linkList.Digraph;
	private var sim:Simulator;

	public function new( _sim:Simulator ) {
		sim = _sim;
		genDigraph();
	}

	private function genDigraph() {
		dg = new graph.linkList.Digraph();
		genVertices();
		genArcs();
	}

	private function genVertices() {
		print( "\tVertices..." );
		for ( node in sim.state.network.nodes )
			dg.addVertex( node );
		println( "\r\t"+countIterator( dg.vertices() )+" vertices..." );
	}

	private function genArcs() {
		print( "\tArcs..." );
		for ( link in sim.state.network.links )
			dg.addArc( link );
		println( "\r\t"+countIterator( dg.arcs() )+" arcs..." );
	}

	private static function countIterator<T>( it:Iterator<T> ):Int {
		var i = 0;
		for ( v in it )
			i++;
		return i;
	}

}
