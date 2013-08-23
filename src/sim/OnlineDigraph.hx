package sim;

import elebeta.ett.rodoTollSim.*;
import graph.adjLists.Arc;
import graph.adjLists.Digraph;

import Lambda.array;

import Lambda.count;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;
import sim.SimulatorState;

private typedef Thread = #if ( neko )                             neko.vm.Thread;
                         #elseif ( cpp && HXCPP_MULTI_THREADED )   cpp.vm.Thread;
                         #elseif ( java )                         java.vm.Thread;
                         #else                                         Null<Int>;
                         #end

class OnlineDigraph {

	public var workers(default,null):Int;
	public var partSize(default,null):Int;

	public var heapArity(get,set):Int;
	public var heapReserve(get,set):Int;

	private var ws:Array<Thread>;

	private var dg:Digraph;
	private var sim:Simulator;

	public function new( _sim:Simulator, _workers, _partSize ) {
		sim = _sim;
		workers = _workers;
		partSize = _partSize;
		if ( workers <= 1 ) {
			workers = 1;
			genDigraph();
		}
		else { // multithreaded
			genStubDigraph();
			ws = [];
			for ( i in 0...workers ) {
				var w = spawnWorker( i, sim );
				ws.push( w );
				sendMsg( ws[i], -1, MPrepare( sim ) );
			}
			for ( i in 0...workers ) {
				var res = readMsg( true );
				switch ( res.data ) {
				case MReady: println( "Worker #"+res.from+" ready" );
				case all: throw all;
				}
			}
		}
	}

	public function run( ods:Iterable<elebeta.ett.rodoTollSim.OD>, volumes:Bool, path:Bool ) {
		var wgts = sim.state.sampleWeights;
		if ( workers == 1 ) {
			var odCnt = count( ods );
			println( "\tD-ary heap arity = "+heapArity );
			println( "\tD-ary heap initial reserve = "+heapReserve );
			var lt = haxe.Timer.stamp();
			var i = 0;
			print( "\rRunning "+i+"/"+odCnt );
			for ( od in ods ) {
				var w = od.sampleWeight;
				if ( wgts != null && wgts.exists( od.id ) )
					w = wgts.get( od.id );
				runEach( od, w, volumes, path );
				i++;
				if ( haxe.Timer.stamp() - lt > .2 ) {
					lt = haxe.Timer.stamp();
					print( "\rRunning "+i+"/"+odCnt+" paths" );
				}
			}
			println( "\rRunning "+i+"/"+odCnt+" paths... Done" );
		}
		else {
			var ods = array( ods );
			println( "\tD-ary heap arity = "+heapArity );
			println( "\tD-ary heap initial reserve = "+heapReserve );
			println( "\tEXPERIMENTAL MULTITHREADED MODE: "+workers+" workers with part size = "+partSize );
			var lt = haxe.Timer.stamp();
			for ( w in ws )
				sendMsg( w, -1, MPing );
			var sent = 0;
			var recv = 0;
			var i = 0;
			print( "\rRunning "+i+"/"+ods.length );
			while ( i < ods.length ) {
				var nextEnd = i + partSize;
				if ( nextEnd >= ods.length )
					nextEnd = ods.length;
				var msg = readMsg( true );
				switch ( msg.data ) {
				case MAlive:
					sendMsg( ws[msg.from], -1, MRun( ods, i, nextEnd, volumes, path ) );
					sent += nextEnd - i;
					i = nextEnd;
				case MDone( ps, cnt ):
					recv += cnt;
					print( "\rRunning "+recv+"/"+ods.length+" paths" );
					sendMsg( ws[msg.from], -1, MRun( ods, i, nextEnd, volumes, path ) );
					sent += nextEnd - i;
					i = nextEnd;
					incorporatePseudoState( sim.state, ps );
				case all:
					throw all;
				}
			}
			while ( recv < sent ) {
				var msg = readMsg( true );
				switch ( msg.data ) {
				case MDone( ps, cnt ):
					recv += cnt;
					print( "\rRunning "+recv+"/"+ods.length+" paths" );
					incorporatePseudoState( sim.state, ps );
				case all:
					throw all;
				}
			}
			println( "\rRunning "+i+"/"+ods.length+" paths... Done" );

		}
	}

	public function prepareForInvalidation() {
		if ( workers > 1 ) {
			for ( w in ws )
				sendMsg( w, -1, MKill );
			for ( i in 0...workers ) {
				var res = readMsg( true );
				switch ( res.data ) {
				case MExiting: // ok
				case all: throw all;
				}
			}
		}
	}

	// PROPERTIES ---------------------------------------------------------------

	private function get_heapArity() return dg.queueArity;
	private function set_heapArity( a:Int ) {
		if ( workers == 1 )
			return dg.queueArity = a;
		else
			throw "Heap arity changes are not possible in multi-threaded mode";
	}
	private function get_heapReserve() return dg.queueReserve;
	private function set_heapReserve( a:Int ) {
		if ( workers == 1 )
			return dg.queueReserve = a;
		else
			throw "Heap initial reserve changes are not possible in multi-threaded mode";
	}


	// RUNNING ------------------------------------------------------------------

	private function runEach( od:elebeta.ett.rodoTollSim.OD, weight:Float, volumes:Bool, path:Bool ) {
		
		var origin = findEntry( od.origin.x, od.origin.y ); // find closest
		var destination = findEntry( od.destination.x, od.destination.y ); // find closest

		// trace( destination );
		if ( origin == destination ) {
			sim.state.results.set( od.id, ODResult.make( od.id, weight, false, false, null, null, null, null, null, null ) );
			return;
		}

		var vehicle = sim.state.network.vehicles.get( od.vehicleId ); // from online network
		var ucost = new def.UserCostModel( od.distWeight, od.timeSocialWeight, od.timeOperationalWeight ); // from flat od
		
		dg.stpath( origin, destination, vehicle, ucost );

		var t = dg.getVertex( destination );
		if ( t.parent == null ) {
			sim.state.results.set( od.id, ODResult.make( od.id, weight, true, false, null, null, null, null, null, null ) );
			return;
		}

		var res = ODResult.make( od.id, weight, true, true, t.dist, t.time, t.toll, t.cost, null, null );
		if ( volumes || path ) {
			var traversor = new Traversor( weight, vehicle, volumes, path );
			dg.revPathFold( destination, traversor.traverse, 0 );
			if ( traversor.volumes != null ) {
				for ( v in traversor.volumes )
					if ( sim.state.volumes.exists( v.linkId ) )
						sim.state.volumes.get( v.linkId ).sum( v );
					else
						sim.state.volumes.set( v.linkId, v );
			}
			if ( traversor.path != null ) {
				res.path = array( traversor.path );
			}
		}
		sim.state.results.set( od.id, res );

	}

	private function findEntry( x:Float, y:Float ):def.Node {
		return sim.state.network.findNearestNode( x, y );
	}


	// GENERATION ---------------------------------------------------------------

	private function genDigraph() {
		switch ( sim.state.algorithm ) {
		case ADijkstra: dg = new Digraph( false, sim.state.heapArity, sim.state.heapReserve );
		case AAStar: dg = new Digraph( true, sim.state.heapArity, sim.state.heapReserve );
		case ABellmanFord: throw "Bellman Ford not working for now";
		}
		genVertices();
		genArcs();
	}

	private function genVertices() {
		if ( workers < 1 )
			print( "\tVertices..." );
		for ( node in sim.state.network.nodes )
			dg.addVertex( node );
		if ( workers < 1 )
			println( "\r\t"+countIterator( dg.vertices() )+" vertices..." );
	}

	private function genArcs() {
		if ( workers < 1 )
			print( "\tArcs..." );
		for ( link in sim.state.network.links )
			dg.addArc( link );
		if ( workers < 1 )
			println( "\r\t"+countIterator( dg.arcs() )+" arcs..." );
	}

	private static function countIterator<T>( it:Iterator<T> ):Int {
		var i = 0;
		for ( v in it )
			i++;
		return i;
	}


	// MULTITHREADED ------------------------------------------------------------

	private static function spawnWorker( id:Int, sim:Simulator ):Thread {
		var w = threadCreate( threadMain );
		sendMsg( w, -1, MInit( curThread(), id ) );
		switch ( readMsg( true ).data ) {
		case MAlive:
		case all: throw all;
		}
		return w;
	}

	private static function threadCreate( main:Void->Void ):Thread {
		return #if ( neko )
		Thread.create( main );
		#elseif ( cpp && HXCPP_MULTI_THREADED )
		Thread.create( main );
		#elseif ( java )
		Thread.create( main );
		#else
		throw "Threads not avaibable in this build";
		#end
	}

	private static function readMsg( block:Bool ):Message {
		return #if ( neko )
		Thread.readMessage( block );
		#elseif ( cpp && HXCPP_MULTI_THREADED )
		Thread.readMessage( block );
		#elseif ( java )
		Thread.readMessage( block );
		#else
		throw "Threads not avaibable in this build";
		#end
	}

	private static function sendMsg( thread:Thread, from:Int, data:MessageData ) {
		#if ( neko )
		thread.sendMessage( new Message( from, data ) );
		#elseif ( cpp && HXCPP_MULTI_THREADED )
		thread.sendMessage( new Message( from, data ) );
		#elseif ( java )
		thread.sendMessage( new Message( from, data ) );
		#else
		throw "Threads not avaibable in this build";
		#end
	}

	private static function curThread() {
		return #if ( neko )
		Thread.current();
		#elseif ( cpp && HXCPP_MULTI_THREADED )
		Thread.current();
		#elseif ( java )
		Thread.current();
		#else
		throw "Threads not avaibable in this build";
		#end
	}

	private static function threadMain():Void {
		// initial handshake
		// receive parent
		var parent:Thread = null;
		var id= -1;
		// and respond
		switch ( readMsg( true ).data ) {
		case MInit( p, i ): parent = p; id = i; sendMsg( parent, id, MAlive );
		case all: throw all;
		}

		// preparing for jobs
		// receive sim
		var sim:Simulator = null;
		switch ( readMsg( true ).data ) {
		case MPrepare( s ): sim = s;
		case all: throw all;
		}
		// self gen
		var self = new OnlineDigraph( sim, 1, 0 );
		var wgts = sim.state.sampleWeights;
		// set self.workers to impossible number
		self.workers = -999;
		// report availability
		sendMsg( parent, id, MReady );

		// enter work loop
		do {
			switch ( readMsg( true ).data ) {
			case MRun( ods, begin, end, volumes, path ):
				// generate a pseudo state
				self.sim = Type.createEmptyInstance( Simulator );
				self.sim.state = new sim.SimulatorState( sim.state.newline
				, sim.state.algorithm, sim.state.heapArity, sim.state.heapReserve );
				self.sim.state.network = sim.state.network;
				self.sim.state.results = new Map();
				if ( volumes )
					self.sim.state.volumes = new Map();

				// run all job units
				var cnt = 0;
				for ( i in begin...end ) {
					var od = ods[i];
					var w = od.sampleWeight;
					if ( wgts != null && wgts.exists( od.id ) )
						w = wgts.get( od.id );
					self.runEach( ods[i], w, volumes, path );
					cnt++;
				}

				// send back the pseudo state
				sendMsg( parent, id, MDone( self.sim.state, cnt ) );
			case MKill:
				sendMsg( parent, id, MExiting );
				break;
			case MPing:
				sendMsg( parent, id, MAlive );
			case all:
				throw all;
			}
		} while ( true );
	}

	private static function incorporatePseudoState( actual:SimulatorState
	, pseudo:SimulatorState ) {
		for ( r in pseudo.results )
			actual.results.set( r.id, r );
		if ( actual.volumes != null )
			for ( r in pseudo.volumes )
				actual.volumes.set( r.linkId, r );
	}

	private function genStubDigraph() {
		switch ( sim.state.algorithm ) {
		case ADijkstra: dg = new Digraph( false, sim.state.heapArity, sim.state.heapReserve );
		case AAStar: dg = new Digraph( true, sim.state.heapArity, sim.state.heapReserve );
		case ABellmanFord: throw "Bellman Ford not working for now";
		}
	}

}

private class Traversor {

	private var v:def.VehicleClass;
	private var w:Float;
	public var volumes:Array<LinkVolume>;
	public var path:List<Int>;

	public function new( weight:Float, vclass:def.VehicleClass, saveVolumes, savePath ) {
		w = weight;
		v = vclass;
		if ( saveVolumes )
			volumes = [];
		if ( savePath )
			path = new List();
	}

	public inline function traverse( a:Arc, pre:Int ):Int {
		if ( !a.isPseudo() ) {
			if ( volumes != null )
				volumes.push( LinkVolume.make( a.link.id, w, v.noAxis*w, v.tollMulti*w, v.equiv*w ) );
			if ( path != null )
				path.push( a.link.id );
			return pre + 1;
		}
		else
			return pre;
	}

}

private class Message {
	public var from:Int;
	public var data:MessageData;
	public function new( _f, _d ) {
		from = _f;
		data = _d;
	}
}

private enum MessageData {
	// main -> worker
	MInit( parent:Thread, id:Int );
	// main -> worker
	MPing;
	// worker -> main
	MAlive;

	// main -> worker
	MPrepare( sim:Simulator );
	// worker -> main
	MReady;

	// main -> worker
	MRun( ods:Array<elebeta.ett.rodoTollSim.OD>, begin:Int, end:Int, volumes:Bool, path:Bool );
	MDone( pseudoState:SimulatorState, cnt:Int );

	// main -> worker
	MKill;
	// worker -> main
	MExiting;
}
