package graph.linkList;

import def.*;

/* 
 * An arc-list directed graph implementation.
 * This should be especially efficient for the Bellamn-Ford shortest path
 * algorithm.
 */
class Digraph {

	var as:ArcCol;
	var vs:Map<Int,Vertex>;
	
	/* 
	 * Directed graph constructor.
	 */
	public function new() {
		as = new ArcCol();
		vs = new Map();
	}

	/* 
	 * Vertex API
	 */

	/* 
	 * Adds a vertex for [node].
	 * Returns the added vertex on success.
	 * Raises an expection when:
	 * . [node] is {null}.
	 * . [node.id] is already known.
	 */
	public function addVertex( node:Node ):Vertex {
		if ( node == null )
			throw "Null node";
		else if ( vs.exists( node.id ) )
			throw 'There already exists a vertex for node.id=${node.id}';
		else {
			var v = new Vertex( node );
			vs.set( node.id, v );
			return v;
		}
	}

	/* 
	 * Gets the registred vertex for [node].
	 * Returns a vertex on success,
	 * or {null} when:
	 * . [node] is {null}.
	 * . [node] does not have a corresponding vertex.
	 */
	public function getVertex( node:Node ):Null<Vertex> {
		if ( node != null ) {
			var ret = vs.get( node.id );
			return ret != null && ret.node == node ? ret : null;
		}
		else
			return null;
	}

	/* 
	 * Vertices iterator.
	 */
	public function vertices():Iterator<Vertex> {
		return vs.iterator();
	}

	/* 
	 * Arc API
	 */

	/* 
	 * Adds an arc for [link].
	 * Returns the added arc on success.
	 * Raises an expection when:
	 * . [link] is {null}.
	 * . [link.id] is already known.
	 * . [link.start] has no known vertex.
	 * . [link.finish] has no known vertex.
	 */
	public function addArc( link:Link ):Arc {
		if ( link == null )
			throw "Null link";
		else if ( as.exists( link.id ) )
			throw 'There already exists an arc for link.id=${link.id}';
		else {
			var v = getVertex( link.start );
			if ( v == null )
				throw 'Cannot add arc, unknown start node ${link.start.id}';
			var w = getVertex( link.finish );
			if ( w == null )
				throw 'Cannot add arc, unknown finish node ${link.finish.id}';
			var a = new Arc( v, w, link );
			as.set( a );
			return a;
		}
	}

	/* 
	 * Gets the registred arc for [link].
	 * Returns an arc on success,
	 * or {null} when:
	 * . [link] is {null}.
	 * . [link] does not have a corresponding arc.
	 */
	public function getArc( link:Link ):Null<Arc> {
		if ( link != null ) {
			var ret = as.get( link.id );
			return ret != null && ret.link == link ? ret : null;
		}
		else
			return null;
	}

	/* 
	 * Arcs iterator.
	 */
	public function arcs():Iterator<Arc> {
		return as.iterator();
	}

	/* 
	 * Shortest paths API - low level
	 */

	/* 
	 * Clears all state from all vertices.
	 */
	public function clearState() {
		for ( v in vs )
			v.clearState();
	}

	/* 
	 * Sets a vertex initial state for a shortest path tree.
	 */
	public function setVertexInitialState( node:Node, dist:Float, time:Float
	, cost:Float, toll:Float ) {
		var vertex = getVertex( node );
		vertex.dist = dist;
		vertex.time = time;
		vertex.cost = cost;
		vertex.toll = toll;
		vertex.parent = new PseudoArc( vertex );
	}

	/* 
	 * Performs the Bellman-Ford relaxation for computing a shortest path tree.
	 * Relaxes all arcs, updating finish node state when it would decrease its
	 * generalized cost.
	 */
	public function bellmanFordRelaxation( tollMulti:Float, vclass:VehicleClass
	, ucost:UserCostModel, selectedToll:Link ) {
		var relaxing = 1;
		var i = 0;
		while ( relaxing > 0 ) {
			relaxing = 0;
			for ( a in as )
				if ( relax( a, tollMulti, vclass, ucost, selectedToll ) )
					relaxing++;
			i++;
		}
		trace( 'done in $i iterations' );
	}

	/* 
	 * Functional fold of the reverse path (or precedence list).
	 * If there is no path (no vertex found with parent set to itself), this
	 * method returns {null}.
	 */
	@:generic
	public function revPathFold<T>( destination:Node, f:Arc->T->T, first:T ):Null<T> {
		var t = getVertex( destination ).parent;
		while ( t != null ) {
			first = f( t, first );
			if ( t.isPseudo() )
				return first;
			else
				t = t.from.parent;
		}
		return null;
	}

	/* 
	 * Shortest paths API - high level
	 */

	/* 
	 * Simple Single Source Shortest Path Tree - simple SSSPT.
	 */
	public function simpleSSSPT( origin:Node, tollMulti:Float, vclass:VehicleClass
	, ucost:UserCostModel, ?selectedToll:Link ) {
		clearState();
		setVertexInitialState( origin, 0., 0., 0., 0. );		
		bellmanFordRelaxation( tollMulti, vclass, ucost, selectedToll );
	}

	/* 
	 * Helper functions
	 */

	/* 
	 * Arc relaxation.
	 */
	inline function relax( a:Arc, tollMulti:Float, vclass:VehicleClass
	, ucost:UserCostModel, selectedToll:Link ):Bool {
		if ( a.from.parent == null ) {
			// nothing to do, link not reached yet
			return false;
		}
		else {
			// tentative costs
			var tdist = a.from.dist + a.link.dist;
			var ttime = a.from.time + a.time( vclass );
			var ttoll = a.from.toll + a.toll( tollMulti );
			var tcost = ucost.userCost( tdist, ttime, ttoll );

			// relaxation
			if ( tcost < a.to.cost ) {
				a.to.dist = tdist;
				a.to.time = ttime;
				a.to.toll = ttoll;
				a.to.cost = tcost;
				a.to.parent = a;
				a.to.selectedToll = a.from.selectedToll
				|| ( selectedToll != null && a.link == selectedToll );
				return true;
			}
			else
				return false;
		}
	}

}

/* 
 * Arc collection:
 * . unsorted map keyed by arc [link.id]
 * . fast iterator
 */
private class ArcCol {

	var array:Array<Arc>;
	var linkMap:Map<Int,Arc>;

	public function new() {
		array = [];
		linkMap = new Map();
	}

	public function exists( linkId:Link.LinkId ):Bool {
		return linkMap.exists( linkId );
	}

	public function get( linkId:Link.LinkId ):Null<Arc> {
		return linkMap.get( linkId );
	}

	/* 
	 * UNSAFE set operation for this collection.
	 * The arc MUST NOT already be registred.
	 */
	public function set( arc:Arc ):Arc {
		linkMap.set( arc.link.id, arc );
		array.push( arc );
		return arc;
	}

	public function iterator() return array.iterator();

}
