package sim;

import elebeta.ds.tree.Rj1Tree;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class OnlineNetwork {

	public var nodes:Map<Int,def.Node>;
	public var nodeSpace:Rj1Tree<def.Node>;
	public var links:Map<Int,def.Link>;
	public var vehicles:Map<Int,def.VehicleClass>;
	public var speeds:Map<Int,def.Speed>; // indexed by typeId
	private var sim:Simulator;

	public function new( _sim:Simulator ) {
		sim = _sim;
		genNodes();
		genVehicles();
		genSpeeds();
		genLinks();
	}

	public function findNearestNode( x:Float, y:Float ):def.Node {
		var dx = 1e-6*(nodeSpace.xMax - nodeSpace.xMin);
		var dy = 1e-6*(nodeSpace.xMax - nodeSpace.xMin);
		var list;
		do {
			list = new List();
			for ( n in nodeSpace.search( x-.5*dx,y-.5*dy,dx,dy ) )
				list.add( n );
			dx *= 2.;
			dy *= 2.;
		} while ( list.isEmpty() );
		var minDist:def.Dist = Math.POSITIVE_INFINITY;
		var n:def.Node = null;
		for ( c in list ) {
			var d = dist( c.x-x, c.y-y );
			if ( d < minDist ) {
				minDist  = d;
				n = c;
			}
		}
		return n;
	}

	private function dist( dx:Float, dy:Float ):def.Dist {
		return Math.sqrt( dx*dx + dy*dy );
	}

	private function genNodes() {
		print( "\tNodes..." );
		nodes = new Map();
		nodeSpace = new Rj1Tree<def.Node>( 16, true );
		var flatNodes = sim.state.nodes; // just a shortcut
		if ( flatNodes == null ) throw "No nodes";
		for ( flat in flatNodes ) {
			var n = new def.Node( flat.id, flat.point.x, flat.point.y );
			nodes.set( n.id, n );
			nodeSpace.insertPoint( n.x, n.y, n );
		}
		println( "\r\t"+Lambda.count( nodes )+" nodes..." );
	}

	private function genVehicles() {
		print( "\tVehicles..." );
		vehicles = new Map();
		var flatVehicles = sim.state.vehicles; // just a shortcut
		if ( flatVehicles == null ) throw "No vehicles";
		for ( flat in flatVehicles ) {
			var n = new def.VehicleClass( flat.id, flat.noAxis, flat.tollMulti, flat.eqNo, flat.name );
			vehicles.set( n.id, n );
		}
		println( "\r\t"+Lambda.count( vehicles )+" vehicles..." );
	}

	private function genSpeeds() {
		print( "\tSpeeds..." );
		speeds = new Map();
		var flatSpeeds = sim.state.speeds; // just a shortcut
		if ( flatSpeeds == null ) throw "No speeds";
		for ( flat in flatSpeeds ) {
			var n = speeds.get( flat.typeId );
			if ( n == null ) speeds.set( flat.typeId, n = new def.Speed() );
			n.set( vehicles.get(flat.vehicleId), flat.speed );
		}
		println( "\r\t"+Lambda.count( speeds )+" speeds levels (vehicle,type combinations)..." );
	}

	private function genLinks() {
		print( "\tLinks..." );
		links = new Map();
		var flatLinks = sim.state.links; // just a shortcut
		if ( flatLinks == null ) throw "No links";
		for ( flat in flatLinks ) {
			var start = nodes.get( flat.startNodeId );
			var finish = nodes.get( flat.finishNodeId );
			var speed = speeds.get( flat.typeId );
			var n = new def.Link( flat.id, start, finish, flat.extension, speed, flat.toll );
			links.set( n.id, n );
		}
		println( "\r\t"+Lambda.count( links )+" links..." );
	}

}
