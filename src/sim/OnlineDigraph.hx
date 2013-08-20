package sim;

import elebeta.ett.rodoTollSim.LinkVolume;
import graph.linkList.Arc;

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

	public function run( od:elebeta.ett.rodoTollSim.OD ) {
		dg.clearState();

		var origin = findEntry( od.origin.x, od.origin.y ); // find closest
		var destination = findEntry( od.destination.x, od.destination.y ); // find closest
		trace( destination );
		if ( origin == destination ) {
			println( "Skipping O/D "+od.id+": origin == destination ("+origin.id+")" );
			return;
		}

		var vehicle = sim.state.network.vehicles.get( od.vehicleId ); // from online network
		var ucost = new def.UserCostModel( od.distWeight, od.timeSocialWeight, od.timeOperationalWeight ); // from flat od
		
		dg.simpleSSSPT( origin, vehicle.tollMulti, vehicle, ucost );
	}

	public function getMoreResults( od:elebeta.ett.rodoTollSim.OD, fexpMulti:Float, keepPath:Bool ) {
		var destination = findEntry( od.destination.x, od.destination.y ); // find closest
		var vehicle = sim.state.network.vehicles.get( od.vehicleId ); // from online network
		var savers = new VolumeSaver( sim, fexpMulti, fexpMulti*vehicle.noAxis
		, vehicle.tollMulti*fexpMulti, vehicle.equiv*fexpMulti, keepPath );
		var cnt = dg.revPathFold( destination, savers.save, 0 );
		// todo save path
	}

	// RUNNING ------------------------------------------------------------------

	private function findEntry( x:Float, y:Float ):def.Node {
		var bestNode = null;
		var minDist = Math.POSITIVE_INFINITY;
		for ( v in dg.vertices() ) {
			var tdist = dist( v.node.x - x, v.node.y - y );
			if ( tdist < minDist ) {
				bestNode = v.node;
				minDist = tdist;
			}
		}
		return bestNode;
	}

	private function dist( dx:Float, dy:Float ):Float {
		return Math.sqrt( dx*dx + dy*dy );
	}

	// RESULTS ------------------------------------------------------------------



	// GENERATION ---------------------------------------------------------------

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

private class VolumeSaver {

	private var vehicles:Float;
	private var axis:Float;
	private var tolls:Float;
	private var equivalentVehicles:Float;
	private var path:Null<List<def.Link>>;
	private var sim:Simulator;

	public function new( _sim:Simulator, _vehicles:Float, _axis:Float
	, _tolls:Float, _equivalentVehicles:Float, _keepPath:Bool ) {
		sim = _sim;
		vehicles = _vehicles;
		axis = _axis;
		tolls = _tolls;
		equivalentVehicles = _equivalentVehicles;
		if ( _keepPath )
			path = new List();
	}

	public function save( a:Arc, pre:Int ):Int {
		var vol = getVolume( a );
		if ( vol != null ) vol.sum( vehicles, axis, tolls, equivalentVehicles );
		if ( path != null ) path.push( a.link );
		return pre + 1;
	}

	private function getVolume( a:Arc ):Null<LinkVolume> {
		if ( a.link == null ) return null;
		else {
			if ( sim.state.volumes == null )
				sim.state.volumes = new Map();
			var x = sim.state.volumes.get( a.link.id );
			if ( x == null ) sim.state.volumes.set( a.link.id, x = LinkVolume.make( a.link.id, 0, 0, 0, 0 ) );
			return x;
		}
	}

}
