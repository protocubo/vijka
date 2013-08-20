package graph.adjLists;

import def.*;

/* 
 * An adjacency-lists directed graph implementation; this should be especially
 * efficient for Dijkstra's (and A*) algorithm
 */
class Digraph {

	private var as:Map<Int,Arc>;
	private var vs:Map<Int,Vertex>;
	
	public var heuristic:Bool;

	// CONSTRUCTION, POPULATION AND BASIC QUERIES -------------------------------

	/* 
	 * Directed graph constructor
	 */
	public function new() {
		as = new Map();
		vs = new Map();
		heuristic = true;
	}

	/* 
	 * Vertex API
	 */

	/* 
	 * Adds a vertex for [node]
	 * Returns the added vertex on success
	 * Raises an expection when
	 * . [node] is {null}
	 * . [node.id] is already known
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
	 * Gets the registred vertex for [node]
	 * Returns a vertex on success
	 * or {null} when:
	 * . [node] is {null}
	 * . [node] does not have a corresponding vertex
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
	 * Vertices iterator
	 */
	public function vertices():Iterator<Vertex> {
		return vs.iterator();
	}

	/* 
	 * Arc API
	 */

	/* 
	 * Adds an arc for [link]
	 * Returns the added arc on success
	 * Raises an expection when:
	 * . [link] is {null}
	 * . [link.id] is already known
	 * . [link.start] has no known vertex
	 * . [link.finish] has no known vertex
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
			as.set( link.id, a );
			v.adjs.push( a );
			return a;
		}
	}

	/* 
	 * Gets the registred arc for [link]
	 * Returns an arc on success
	 * or {null} when:
	 * . [link] is {null}
	 * . [link] does not have a corresponding arc
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
	 * Arcs iterator
	 */
	public function arcs():Iterator<Arc> {
		return as.iterator();
	}


	// SHORTESTS PATHS ----------------------------------------------------------

	// all state
	public inline function clearState() {
		clearCosts();
		clearWeights();
	}

	// just a path (if `keepCosts == true`)
	public inline function clearPath( ?keepCosts=false ) {
		if ( keepCosts )
			for ( v in vs )
				v.clearPath();
		else
			clearCosts();
	}

	// all vertex state
	public inline function clearCosts() {
		for ( v in vs )
			v.clearState();
	}

	// all arc state
	public function clearWeights() {
		for ( a in as )
			a.clearState();
	}

	@:access( graph.adjLists.Vertex )
	public function stpath( source:Node, destination:Node, vclass:VehicleClass, ucost:UserCostModel, ?keepCosts=false ) {
		var s = getVertex( source );
		var t = getVertex( destination );

		clearPath( keepCosts );
		if ( !keepCosts ) {
			s.parent = new PseudoArc( s );
			s.dist = 0; s.time = 0; s.toll = 0; s.cost = 0;
			s.est = s.cost + hf(s,t,ucost);
		}

		weighting( vclass, ucost );

		#if ( debug || TRACES )
		var _maxQueue = 0;
		var _visArcs = 0;
		#end

		var Q = new Queue( 4, 128 );
		Q.put( s );

		while ( Q.notEmpty() ) {
			#if ( debug || TRACES )
			if ( Q.length > _maxQueue ) _maxQueue = Q.length;
			#end

			var v = Q.extract();
			if ( v == t ) break;
			for ( a in v.adjs ) {
				#if ( debug || TRACES )
				_visArcs++;
				#end
				var tdist = v.dist + a.dist;
				var ttime = v.time + a.time;
				var ttoll = v.toll + a.toll;
				var tcost = ucost.userCost( tdist, ttime, ttoll );
				if ( tcost < a.to.cost ) {
					a.to.dist = tdist;
					a.to.time = ttime;
					a.to.toll = ttoll;
					a.to.cost = tcost;
					a.to.parent = a;
					a.to.est = tcost + hf(v,t,ucost);
					Q.update( a.to );
				}
			}
		}

		#if ( debug || TRACES )
		trace( 'Max queue size = $_maxQueue, visited arcs = $_visArcs' );
		trace( 'Destination cost = ${t.cost}' );
		#end
	}


	// SHORTEST PATHS: INTERNALS ------------------------------------------------

	// heuristic function
	private inline function hf( v:Vertex, dest:Vertex, ucost:UserCostModel ):Cost {
		return heuristic ? ucost.a*dist( dest.node.x-v.node.x, dest.node.y-v.node.y ) : 0.;
	}

	private inline function weighting( vclass:VehicleClass, ucost:UserCostModel ) {
		for ( a in as )
			a.weight( vclass, ucost );
	}


	// HELPERS ------------------------------------------------------------------

	private static function dist( dx:Float, dy:Float ):Dist {
		return Math.sqrt( dx*dx + dy*dy )*100.;
	}

}
