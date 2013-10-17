package tools;

import elebeta.ett.vijka.*;
import format.ett.Geometry;
import sim.SimulatorState;

import Math.sqrt;

using sim.SimulatorStateTools;

class Splitter {

	public static
	function split( state:SimulatorState, link:Link, node:Node, id1:Int, id2:Int, cloneAliases:Bool ) {

	}

	var state:SimulatorState;

	function new( state:SimulatorState, link:Link, node:Node, id1:Int, id2:Int ) {
		this.state = state;

		var shp = state.getShape( link ).shape.array();
		var splitPos = findSplitPos( shp, node.point );

		var shp1 = shp.slice( 0, splitPos );
		var shp2 = shp.slice( splitPos );
		
		var shp1e = 0; var shp2e = 0;

		var ext1 = link.extension*shp1e/( shp1e+shp2e );
		var ext2 = link.extension - ext1;

		var link1 = Link.make( id1, link.startNodeId, link.finishNodeId, ext1, link.typeId, link.toll*ext1/link.extension );
		addLink( link1, shp1, link );
		var link2 = Link.make( id2, link.startNodeId, link.finishNodeId, ext2, link.typeId, link.toll*ext2/link.extension );
		addLink( link2, shp2, link );
	}

	function cloneLinkAliases( src:Int, dst:Int ) {
		for ( alias in state.aliases.keys() ) {
			if ( Lambda.has( state.aliases.get( alias ), src ) )
				state.aliases.get( alias ).push( dst );
		}
	}

	function removeAliases( id:Int ) {
		for ( alias in state.aliases.keys() ) {
			state.aliases.get( alias ).remove( id );
		}
	}

	function addLink( link:Link, shp:Array<Point>, cloneAliases:Null<Link> ) {
		state.links.set( link.id, link );
		state.shapes.set( link.id, LinkShape.make( link.id, new LineString( shp ) ) );
		if ( cloneAliases != null )
			cloneLinkAliases( cloneAliases.id, link.id );
	}

	function removeLink( link:Link ) {
		state.links.remove( link.id );
		state.shapes.remove( link.id );
		removeAliases( link.id );
	}

	// static helpers ---

	/**
		Best position to insert `pt` in a shape; as of now, it chooses the spot just after the closest point on the shape
	**/
	static
	function findSplitPos( shp:Array<Point>, pt:Point ):Int {
		var min = Math.NEGATIVE_INFINITY;
		var best = -1;
		for ( i in 0...shp.length ) {
			var tdist = pdist( shp[i], pt );
			if ( tdist < min ) {
				min = tdist;
				best = i;
			}
		}
		return best + 1;
	}

	static
	function pdist( a:Point, b:Point ) {
		return sqrt( sq(a.x-b.x) + sq(a.y-b.y) );
	}

	static
	function sq( v:Float ) {
		return v*v;
	}

}
