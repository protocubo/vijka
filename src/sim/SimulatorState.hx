package sim;

import elebeta.ett.rodoTollSim.*;

import sim.Algorithm;
import sim.col.*;

class SimulatorState {

	public var newline:String;

	public var nodes:Null<Map<Int,Node>>;
	public var linkTypes:Null<Map<Int,LinkType>>;
	public var links:Null<Map<Int,Link>>;
	public var vehicles:Null<Map<Int,Vehicle>>;
	public var speeds:Null<LinkTypeSpeedMap>;

	public var shapes:Null<Map<Int,LinkShape>>;

	public var ods:Null<Map<Int,OD>>;
	public var activeOds:Null<Array<OD>>;
	public var activeOdFilter:Null<Array<String>>;

	public var sampleWeights:Null<Map<Int,Float>>; // maps OD::id to Float expansion factor

	public var volumes:Null<Map<Int,LinkVolume>>;
	public var results:Null<Map<Int,ODResult>>;

	public var algorithm:Algorithm;

	public var network:Null<OnlineNetwork>;
	public var digraph:Null<OnlineDigraph>;

	public var heapArity:Int;
	public var heapReserve:Int;

	public function new( _newline, _algorithm, _heapArity, _heapReserve ) {
		newline = _newline;
		algorithm = _algorithm;
		heapArity = _heapArity;
		heapReserve = _heapReserve;
	}
	
	public function invalidate() {
		network = null;
		digraph = null;
	}

	public function clearResults() {
		volumes = null;
		results = null;
	}

}
