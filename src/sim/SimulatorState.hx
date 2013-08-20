package sim;

import graph.linkList.Digraph;

import elebeta.ett.rodoTollSim.*;

class SimulatorState {

	public var nodes:Null<Map<Int,Node>>;
	public var linkTypes:Null<Map<Int,LinkType>>;
	public var links:Null<Map<Int,Link>>;

	public var network:Null<OnlineNetwork>;
	public var digraph:Null<Digraph>;

	public function new() {

	}
	
	public inline function invalidate() {
		network = null;
		digraph = null;
	}

}
