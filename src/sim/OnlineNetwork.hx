package sim;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class OnlineNetwork {

	public var nodes:Map<Int,def.Node>;
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

	private function genNodes() {
		print( "\tNodes..." );
		nodes = new Map();
		var flatNodes = sim.state.nodes; // just a shortcut
		if ( flatNodes == null ) throw "No nodes";
		for ( flat in flatNodes ) {
			var n = new def.Node( flat.id, flat.point.x, flat.point.y );
			nodes.set( n.id, n );
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
		println( "\r\t"+Lambda.count( speeds )+" speeds..." );
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
