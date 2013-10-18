package tools;

import elebeta.ett.vijka.*;
import format.ett.Geometry;
import jonas.Vector;
import sim.SimulatorState;

import Math.acos;
import Math.PI;
import Math.sqrt;

using sim.SimulatorStateTools;

class Splitter {

	public static
	function split( state:SimulatorState, linkId:Int, nodeId:Int, dst1:Int, dst2:Int, cloneAliases:Bool ) {
		var node = state.getNode( nodeId );
		var link = state.getLink( linkId );
		if ( state.hasLink( dst1 ) )
			throw "Link `"+dst1+"` already exists";
		if ( state.hasLink( dst2 ) )
			throw "Link `"+dst2+"` already exists";
		return new Splitter( state, link, node, dst1, dst2, cloneAliases );
	}

	public
	var link1:Link;

	public
	var link2:Link;

	var state:SimulatorState;

	function new( state:SimulatorState, link:Link, node:Node, id1:Int, id2:Int, cloneAliases:Bool ) {
		this.state = state;

		var lstr = state.getShape( link ).shape.array();
		var splitPos = findSplitPos( lstr, node.point );
		// trace( splitPos );

		var lstr1 = lstr.slice( 0, splitPos ).concat( [ node.point ] );
		var lstr2 = [ node.point ].concat( lstr.slice( splitPos ) );
		
		var lstr1len = lslen( lstr1 );
		var lstr2len = lslen( lstr2 );
		// trace( [ lslen( lstr ), lstr1len, lstr2len ] );

		var ext1 = link.extension*lstr1len/( lstr1len+lstr2len );
		var ext2 = link.extension - ext1;
		// trace( [ link.extension, ext1, ext2 ] );

		link1 = Link.make( id1, link.startNodeId, node.id, ext1, link.typeId, link.toll*ext1/link.extension );
		addLink( link1, lstr1, link );
		link2 = Link.make( id2, node.id, link.finishNodeId, ext2, link.typeId, link.toll*ext2/link.extension );
		addLink( link2, lstr2, link );

		if ( cloneAliases ) {
			cloneLinkAliases( link.id, link1.id );
			cloneLinkAliases( link.id, link2.id );
		}

		removeLink( link );
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

	function addLink( link:Link, lstr:Array<Point>, cloneAliases:Null<Link> ) {
		state.links.set( link.id, link );
		state.shapes.set( link.id, LinkShape.make( link.id, new LineString( lstr ) ) );
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
		Best position to insert `pt` in a shape
	**/
	static
	function findSplitPos( lstr:Array<Point>, pt:Point ):Int {
		// tries to find the place where inserting the point creates the smallest bend angle
		var vp = pt2vec( pt );
		var min = Math.POSITIVE_INFINITY;
		var best = -1;
		for ( i in 0...(lstr.length-1) ) {
			var v = vp.sub( pt2vec( lstr[i] ) );
			var w = pt2vec( lstr[i+1] ).sub( vp );
			var tdist = vecAngle( v, w );
			if ( tdist < min ) {
				min = tdist;
				best = i;
			}
		}
		return best + 1;
	}

	static
	function pt2vec( pt:Point ) {
		return new Vector( pt.x, pt.y );
	}

	static
	function vec2pt( v:Vector ) {
		return new Point( v.x, v.y );
	}

	static
	function vecAngle( a:Vector, b:Vector ) {
		return acos( a.dotProduct( b )/a.mod()/b.mod() );
	}

	static
	function lslen( lstr:Array<Point> ):Float {
		var len = 0.;
		for ( i in 1...lstr.length )
			len += pdist( lstr[i-1], lstr[i] );
		return len;
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
