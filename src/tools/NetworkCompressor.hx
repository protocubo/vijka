package tools;

import format.ett.Geometry.LineString;
import sim.SimulatorState;
import elebeta.ett.vijka.*;

class NetworkCompressor {

	public static
	function compress( state:sim.SimulatorState ) {
		return new NetworkCompressor( state );
	}
	
	public
	var nodes:Map<Int,Node>;

	public
	var links:Map<Int,Link>;

	public
	var shapes:Map<Int,LinkShape>;

	public
	var aliases:Map<String,Array<Int>>;

	var lastLinkId:Int;

	var linksFrom:Map<Int,Array<Link>>;

	var linksTo:Map<Int,Array<Link>>;

	function new( state:SimulatorState ) {
		cloneState( state );

		indexLinks();
		indexAliases();
		run();
		consolidate();
		rebuildAliases();

		verify();
	}


	// main steps

	function cloneState( state:SimulatorState ) {
		if ( state.nodes == null )
			throw "No nodes";
		nodes = copyMap( state.nodes, new Map() );
		if ( state.links == null )
			throw "No links";
		links = copyMap( state.links, new Map() );
		if ( state.shapes != null )
			shapes = copyMap( state.shapes, new Map() );
		else
			shapes = new Map();
		if ( state.aliases != null )
			aliases = copyMap( state.aliases, new Map() );
		else
			aliases = new Map();

		lastLinkId = ~0x7fffffff; // should be the smallest possible integer
		if ( lastLinkId > 0 || lastLinkId > -1024 )
			throw "Bad " + lastLinkId;
		for ( link in links )
			if ( link.id > lastLinkId )
				lastLinkId = link.id;
	}

	function indexLinks() {
		linksFrom = new Map();
		linksTo = new Map();
		for ( link in links )
			indexLink( link );
	}

	function indexAliases() {

	}

	function run() {
		for ( node in nodes )
			joinNode( node );
	}

	function consolidate() {
		var nnodes = new Map();
		for ( node in nodes ) {
			if ( mmget( linksFrom, node.id ).length > 0 || mmget( linksTo, node.id ).length > 0 )
				nnodes.set( node.id, node );
		}
		nodes = nnodes;

		var nshapes = new Map();
		for ( shape in shapes )
			if ( shape.shape.length > 2 && links.exists( shape.linkId ) )
				nshapes.set( shape.linkId, shape );
		shapes = nshapes;
	}

	function rebuildAliases() {

	}

	function verify() {
		for ( link in links ) {
			if ( !nodes.exists( link.startNodeId ) )
				throw "Missing start node `"+link.startNodeId+"` for link `"+link.id+"`";
			if ( !nodes.exists( link.finishNodeId ) )
				throw "Missing finish node `"+link.finishNodeId+"` for link `"+link.id+"`";
		}
	}


	// adding/indexing or removing/deindexing links

	function indexLink( link:Link ) {
		mmpush( linksFrom, link.startNodeId, link );
		mmpush( linksTo, link.finishNodeId, link );
	}

	function deIndexLink( link:Link ) {
		var linksF = mmget( linksFrom, link.startNodeId );
		linksFrom.remove( link.startNodeId );
		for ( k in linksF )
			if ( k != link )
				mmpush( linksFrom, link.startNodeId, k );
		var linksT = mmget( linksTo, link.finishNodeId );
		linksTo.remove( link.finishNodeId );
		for ( k in linksT )
			if ( k != link )
				mmpush( linksTo, link.finishNodeId, k );
	}

	function addLink( id, startNodeId, finishNodeId, extension, typeId, toll ) {
		var nlink = Link.make( id, startNodeId, finishNodeId, extension, typeId, toll );
		links.set( nlink.id, nlink );
		indexLink( nlink );
		return nlink;
	}

	function removeLink( link:Link ) {
		deIndexLink( link );
		links.remove( link.id );
		shapes.remove( link.id );
	}


	// joins

	function joinNode( node:Node ) {
		// links starting at `node`
		var linksF = mmget( linksFrom, node.id );

		// links ending at `node`
		var linksT = mmget( linksTo, node.id );

		// if a node has more than 2 incoming links and 2 outgoing links, it cannot be joined without copromising
		// the network accesssibility and connectivity
		if ( linksF.length > 2 && linksT.length > 2 )
			return;

		// a node may only be removed if it has **exactly** two neighbors; `a` and `b` will be these neighbors
		var a = null; var b = null;

		// links from `a` to `b`, passing through `node` will be in `anb` and, those from `b` to `a`, will be in `bna`
		var anb = []; var bna = [];

		// setting neighbors and classifying links
		for ( link in linksF ) {
			var t = nodes.get( link.finishNodeId );

			if ( a == null )
				a = t; // first neighbor
			else if ( t != a && b == null )
				b = t; // sencod neighbor
			else if ( t != a && t != b )
				return; // additional neighbor -> abort

			if ( t == a )
				bna.push( link );
			else if ( t == b )
				anb.push( link );
		}
		for ( link in linksT ) {
			var s = nodes.get( link.startNodeId );

			if ( a == null )
				a = s; // first neighbor
			else if ( s != a && b == null )
				b = s; // second neighbor
			else if ( s != a && s != b )
				return; // additional neighbor -> abort

			if ( s == a )
				anb.push( link );
			else if ( s == b )
				bna.push( link );
		}

		// the node can be joined only if links in _both_ directions may be joined, or if there are links in no or only
		// one direction
		// links in one direction can be joined if and only if they are _not parallel_
		// since `anb` and `bna` were just now computed (and assuming this was done correctly), it is safe to assume that
		// checking only one of the endpoints is enough to assure that the links are not parallel
		if ( ( anb.length == 0 || ( anb.length==2 && anb[0].startNodeId!=anb[1].startNodeId ) )
		&& ( bna.length == 0 || ( bna.length==2 && bna[0].startNodeId!=bna[1].startNodeId ) ) ) {
			if ( anb.length == 2 )
				joinLinks( anb[0], anb[1] );
			if ( bna.length == 2 )
				joinLinks( bna[0], bna[1] );
		}
			
	}

	function joinLinks( a:Link, b:Link ) {
		// links with different `typeId` or with positive fare value (`toll`) cannot be joined
		if ( a.typeId != b.typeId || a.toll > 0 || b.toll > 0 )
			return;

		// `b` must start on the node that `a` ended, if this is not the case, they must be swaped
		if ( b.startNodeId != a.finishNodeId ) {
			var _b = a;
			a = b;
			b = _b;
		}
		// enforce it
		if ( b.startNodeId != a.finishNodeId )
			throw "Could not order links `"+a.id+"` and `"+b.id+"` for joining";

		// build the basis of new link
		var nlink = addLink( freeLinkId(), a.startNodeId, b.finishNodeId, a.extension + b.extension, a.typeId, 0 );

		log( a, b, nlink );

		// create its shape
		var shp1 = getShape( a ).shape.array();
		var shp2 = getShape( b ).shape.array();
		var shape = LinkShape.make( nlink.id, new LineString( shp1.concat( shp2.slice( 1 ) ) ) );
		shapes.set( shape.linkId, shape );
		
		// remove their parents
		removeLink( a );
		removeLink( b );
	}


	// other helpers

	public dynamic
	function log( a:Link, b:Link, nlink:Link ) {
		// trace( [ a.id, b.id, nlink.id ] );
	}

	function freeLinkId() {
		return ++lastLinkId;
	}

	function getShape( link:Link ) {
		if ( shapes.exists( link.id ) )
			return shapes.get( link.id );
		else {
			// create the cannonical shape
			var shp = LinkShape.make( link.id, new LineString( [ nodes.get( link.startNodeId ).point, nodes.get( link.finishNodeId ).point ] ) );
			shapes.set( shp.linkId, shp );
			return shp;
		}
	}


	// Map (and multimap) helpers

	/**
		Copies map contents from `source`, to `destination`; returns `destination` with the elements from `source`.
	**/
	function copyMap<K,V>( source:Map<K,V>, destination:Map<K,V> ):Map<K,V> {
		for ( k in source.keys() ) {
			var v = source.get( k );
			destination.set( k, v );
		}
		return destination;
	}

	/**
		Pushes `key`,`value` into multimap `mmap`
	**/
	function mmpush<K,V>( mmap:Map<K,Array<V>>, key:K, value:V ) {
		if ( mmap.exists( key ) )
			mmap.get( key ).push( value );
		else
			mmap.set( key, [ value ] );
	}

	/**
		Gets values for `key` from multimap `map`; if the `key` does not exist, returns an empty array
	**/
	function mmget<K,V>( mmap:Map<K,Array<V>>, key:K ):Array<V> {
		return mmap.exists( key ) ? mmap.get( key ) : [];
	}

}
