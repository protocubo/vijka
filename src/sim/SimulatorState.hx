package sim;

import elebeta.ett.rodoTollSim.*;

import sim.Algorithm;
import sim.col.*;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class SimulatorState {

	public var sim:Simulator;

	public var newline:String;

	public var nodes:Null<Map<Int,Node>>;
	public var linkTypes:Null<Map<Int,LinkType>>;
	public var links:Null<Map<Int,Link>>;
	public var vehicles:Null<Map<Int,Vehicle>>;
	public var speeds:Null<LinkTypeSpeedMap>;

	public var aliases:Null<Map<String,Array<Int>>>;

	public var shapes:Null<Map<Int,LinkShape>>;

	public var ods:Null<Map<Int,OD>>;
	public var activeOds:Null<Array<OD>>;
	public var activeOdFilter:Null<Array<String>>;

	public var sampleWeights:Null<Map<Int,Float>>; // maps OD::id to Float expansion factor

	public var volumes:Null<Map<Int,LinkVolume>>;
	public var results:Null<Map<Int,ODResult>>;

	public var coldStorage:Null<Map<String,StorageBox>>;

	public var algorithm:Algorithm;

	public var network:Null<OnlineNetwork>;
	public var digraph:Null<OnlineDigraph>;

	public var heapArity:Int;
	public var heapReserve:Int;

	public var workers:Int;
	public var workerPartSize:Int;

	public function new( _sim:Simulator, _newline, _algorithm, _heapArity, _heapReserve ) {
		sim = _sim;
		newline = _newline;
		algorithm = _algorithm;
		heapArity = _heapArity;
		heapReserve = _heapReserve;
		workers = 1;
		workerPartSize = 0;
	}

	public function assemble( ?force=false ) {
		if ( force ) {
			println( "Forcing online network and graph assembly" );
			printHL( "-" );
		}
		if ( sim.state.network == null || force ) {
			println( "Assembling the network" );
			digraph = null;
			var nk = network = new OnlineNetwork( sim );
		}
		if ( sim.state.digraph == null || force ) {
			println( "Assembling the (directed) graph" );
			if ( sim.state.digraph != null )
				digraph.prepareForInvalidation();
			var dg = digraph = new OnlineDigraph( sim, workers, workerPartSize );
		}
	}

	public function invalidate() {
		network = null;
		if ( digraph != null )
			digraph.prepareForInvalidation();
		digraph = null;
	}

	public function clearResults() {
		volumes = null;
		results = null;
	}

}
