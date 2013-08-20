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

	public var ods:Null<Map<Int,OD>>;

	public var volumes:Null<Map<Int,LinkVolume>>;

	public var network:Null<OnlineNetwork>;
	public var digraph:Null<OnlineDigraph>;

	public function new() {

	}
	
	public inline function invalidate() {
		network = null;
		digraph = null;
	}

}