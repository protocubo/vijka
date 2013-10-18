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
	function validateNode( state:SimulatorState, node:Node ):Bool {
		if ( !state.hasNode( node.id ) )
			throw "Node `"+node.id+"` does not belong to state";
		else if ( state.getNode( node.id ) != node )
			throw "Node instance reuses id `"+node.id+"` but does not belong to state";
		return true;
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
	function validateLink( state:SimulatorState, link:Link ):Bool {
		if ( !state.hasLink( link.id ) )
			throw "Link `"+link.id+"` does not belong to state";
		else if ( state.getLink( link.id ) != link )
			throw "Link instance reuses id `"+link.id+"` but does not belong to state";
		return true;
	}

	public static
	function hasAlias( state:SimulatorState, alias:String ) {
		return state.aliases != null && state.aliases.exists( alias ) && state.aliases.get( alias ).length != 0;
	}

	public static
	function getAlias( state:SimulatorState, alias:String ) {
		if ( state.hasAlias( alias ) )
			return state.aliases.get( alias );
		else
			throw "No alias `"+alias+"`";
	}

	public static
	function setAlias( state:SimulatorState, alias:String, links:Iterable<Link> ) {
		if ( state.aliases == null )
			state.aliases = new Map();
		var x = state.hasAlias( alias ) ? state.getAlias( alias ) : [];
		for ( link in links )
			if ( state.validateLink( link ) && !Lambda.has( x, link.id ) )
				x.push( link.id );
		state.aliases.set( alias, x );

	}

	public static
	function unsetAlias( state:SimulatorState, alias:String, ?links:Iterable<Link> ) {
		if ( !state.hasAlias( alias ) )
			return;
		var x = state.hasAlias( alias ) ? state.getAlias( alias ) : [];
		if ( links == null ) {
			while ( state.aliases.remove( alias ) ) { }
		}
		else {
			for ( link in links )
				if ( state.validateLink( link ) && Lambda.has( x, link.id ) )
					while ( x.remove( link.id ) ) { }
			state.aliases.set( alias, x );
		}
	}


	public static
	function unsetLinkAliases( state:SimulatorState, link:Link ) {
		if ( state.aliases == null )
			return;
		for ( links in state.aliases )
			while ( links.remove( link.id ) ) { }
	}

	public static
	function cloneLinkAliases( state:SimulatorState, src:Link, dst:Link ) {
		for ( alias in state.aliases.keys() ) {
			if ( Lambda.has( state.aliases.get( alias ), src.id ) )
				state.aliases.get( alias ).push( dst.id );
		}
	}

}
