package sim;

import elebeta.ett.rodoTollSim.*;
import graph.adjLists.Arc;
import graph.adjLists.Digraph;

import Lambda.array;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class OnlineDigraph {

	private var dg:Digraph;
	private var sim:Simulator;

	public function new( _sim:Simulator ) {
		sim = _sim;
		genDigraph();
	}

	public function run( od:elebeta.ett.rodoTollSim.OD, volumes:Bool, path:Bool ) {
		dg.clearState();

		var origin = findEntry( od.origin.x, od.origin.y ); // find closest
		var destination = findEntry( od.destination.x, od.destination.y ); // find closest

		// trace( destination );
		if ( origin == destination ) {
			sim.state.results.set( od.id, ODResult.make( od.id, false, false, 0, 0, 0, 0, null, null ) );
			return;
		}

		var vehicle = sim.state.network.vehicles.get( od.vehicleId ); // from online network
		var ucost = new def.UserCostModel( od.distWeight, od.timeSocialWeight, od.timeOperationalWeight ); // from flat od
		
		dg.stpath( origin, destination, vehicle, ucost );

		var t = dg.getVertex( destination );
		if ( t.parent == null ) {
			sim.state.results.set( od.id, ODResult.make( od.id, true, false, 0, 0, 0, 0, null, null ) );
			return;
		}

		var res = ODResult.make( od.id, true, true, t.dist, t.time, t.toll, t.cost, null, null );
		if ( volumes || path ) {
			var traversor = new Traversor( volumes, path, vehicle );
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

	// RUNNING ------------------------------------------------------------------

	private function findEntry( x:Float, y:Float ):def.Node {
		var bestNode = null;
		var minDist:def.Dist = Math.POSITIVE_INFINITY;
		for ( v in dg.vertices() ) {
			var tdist = dist( v.node.x - x, v.node.y - y );
			if ( tdist < minDist ) {
				bestNode = v.node;
				minDist = tdist;
			}
		}
		return bestNode;
	}

	private function dist( dx:Float, dy:Float ):def.Dist {
		return 100*Math.sqrt( dx*dx + dy*dy );
	}

	// GENERATION ---------------------------------------------------------------

	private function genDigraph() {
		switch ( sim.state.algorithm ) {
		case ADijkstra: dg = new Digraph( dg.heuristic ); ;
		case AAStar: dg = new Digraph( dg.heuristic );
		case ABellmanFord: throw "Bellman Ford not working for now";
		}
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

private class Traversor {

	private var v:def.VehicleClass;
	public var volumes:Array<LinkVolume>;
	public var path:List<Int>;

	public function new( saveVolumes, savePath, vclass:def.VehicleClass ) {
		if ( saveVolumes )
			volumes = [];
		if ( savePath )
			path = new List();
		v = vclass;
	}

	public inline function traverse( a:Arc, pre:Int ):Int {
		if ( !a.isPseudo() ) {
			if ( volumes != null )
				volumes.push( LinkVolume.make( a.link.id, 1, v.noAxis, v.tollMulti, v.equiv ) );
			if ( path != null )
				path.push( a.link.id );
			return pre + 1;
		}
		else
			return pre;
	}

}
