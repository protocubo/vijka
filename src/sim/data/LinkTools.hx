package sim.data;

import elebeta.ett.vijka.*;
import format.ett.Geometry;
import sim.SimulatorState;

using sim.SimulatorStateTools;

class LinkTools {

	public static
	function cannonicalShape( link:Link, state:SimulatorState ) {
		return LinkShape.make( link.id, new LineString( [ state.getNode(link.startNodeId).point, state.getNode(link.finishNodeId).point ] ) );
	}

}
