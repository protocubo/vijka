package sim;

import elebeta.ett.vijka.*;
import sim.SimulatorState;

using sim.data.LinkTools;
using sim.SimulatorStateTools;

class SimulatorStateTools {

	public static
	function getShape( state:SimulatorState, link:Link ) {
		var shape = state.shapes.get( link.id );
		if ( shape == null )
			state.shapes.set( link.id, shape = link.cannonicalShape( state ) );
		return shape;
	}

	public static
	function getNode( state:SimulatorState, id:Int ) {
		if ( state.nodes.exists( id ) )
			return state.nodes.get( id );
		else
			throw "No node `"+id+"`";
	}

}
