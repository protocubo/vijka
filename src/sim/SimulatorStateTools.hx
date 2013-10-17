package sim;

import elebeta.ett.vijka.*;
import sim.SimulatorState;

using sim.data.LinkTools;
using sim.SimulatorStateTools;

class SimulatorStateTools {

	public static
	function getShape( state:SimulatorState, link:Link ):LinkShape {
		state.validateLink( link );
		if ( state.shapes == null )
			state.shapes = new Map();
		var shape = state.shapes.get( link.id );
		if ( shape == null )
			state.shapes.set( link.id, shape = link.cannonicalShape( state ) );
		return shape;
	}

	public static
	function hasNode( state:SimulatorState, id:Int ):Bool {
		return state.nodes != null && state.nodes.exists( id );
	}

	public static
	function getNode( state:SimulatorState, id:Int ):Node {
		if ( state.hasNode( id ) )
			return state.nodes.get( id );
		else
			throw "No node `"+id+"`";
	}

	public static
	function validateNode( state:SimulatorState, node:Node ) {
		if ( !state.hasNode( node.id ) )
			throw "Node `"+node.id+"` does not belong to state";
		else if ( state.getNode( node.id ) != node )
			throw "Node instance reuses id `"+node.id+"` but does not belong to state";
	}

	public static
	function hasLink( state:SimulatorState, id:Int ):Bool {
		return state.links != null && state.links.exists( id );
	}

	public static
	function getLink( state:SimulatorState, id:Int ):Link {
		if ( state.hasLink( id ) )
			return state.links.get( id );
		else
			throw "No link `"+id+"`";
	}

	public static
	function validateLink( state:SimulatorState, link:Link ) {
		if ( !state.hasLink( link.id ) )
			throw "Link `"+link.id+"` does not belong to state";
		else if ( state.getLink( link.id ) != link )
			throw "Link instance reuses id `"+link.id+"` but does not belong to state";
	}

}
