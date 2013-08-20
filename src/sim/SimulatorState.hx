package sim;

import elebeta.ett.rodoTollSim.*;
import graph.linkList.Digraph;

import sim.col.*;

class SimulatorState {

	public var nodes:Null<Map<Int,Node>>;
	public var linkTypes:Null<Map<Int,LinkType>>;
	public var links:Null<Map<Int,Link>>;
	public var vehicles:Null<Map<Int,Vehicle>>;
	public var speeds:Null<LinkTypeSpeedMap>;

	public var network:Null<OnlineNetwork>;
	public var digraph:Null<Digraph>;

	public function new() {

	}
	
	public inline function invalidate() {
		network = null;
		digraph = null;
	}

}
