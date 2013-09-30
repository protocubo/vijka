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
	public var queueArity:Int;
	public var queueReserve:Int;

	public var version(default,null):StateVersion;



	// CONSTRUCTION, POPULATION AND BASIC QUERIES -------------------------------

	/* 
	 * Directed graph constructor
	 */
	public function new( _heuristic:Bool, ?_queueArity=2, ?_queueReserve=32 ) {
		version = new StateVersion();
		as = new Map();
		vs = new Map();
		heuristic = _heuristic;
		queueArity = _queueArity;
		queueReserve = _queueReserve;
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

	public function clearVertexState() {
		for ( v in vs )
			v.clearState();
	}

	public function clearArcWeights() {
		for ( a in as )
			a.clearState();
	}

	/*
		`keepCosts`:
			`false`:   clear all path and cost info when visiting a vertex for the
			           first time
			`true`:    don't alter paths or costs before hand; be sure that only
			           desired data remains there before calling `stpath`; ** MORE
			           TESTING NEEDED! **
	*/
	@:access( graph.adjLists.Vertex )
	public function stpath( source:Node, destination:Node, vclass:VehicleClass
	, ucost:UserCostModel, ?keepCosts=false ) {

		// get corresponding nodes
		var s = getVertex( source );
		var t = getVertex( destination );

		// keepCosts?
		if ( keepCosts ) { // yes => do not clear paths or costs
			// do NOT bumb version to a new one
			// do NOT set source cost and parent
			if ( s.parent == null ) {
				// however, it source has no parent, stpath cannot proceed
				// so raise an execption
				throw "stpath with keep costs active can only proceed if the source"
				+"vertex has been reached or has been manually set with _.parent = new PseudoArc(_)";
			}
			// do NOT clear destination state
		}
		else { // no => compute a NEW path, from s to t
			// bump version to a new one
			var oldVersion = version;
			version = new StateVersion();
			// set source cost and parent
			s.parent = new PseudoArc( s );
			s.dist = 0; s.time = 0; s.toll = 0; s.cost = 0;
			s.est = s.cost + hf(s,t,ucost);
			s.version = version;
			// clear destination state (for safety)
			t.clearState();
		}

		var Q = new Queue( queueArity, queueReserve );
		Q.add( s ); // starting point: s

		while ( Q.notEmpty() ) {

			// next vertex => min cost
			var v = Q.pop();

			// exit early?
			if ( v == t ) break;
			
			for ( a in v.adjs ) {
				// arcs weighting is lazy; weight this arc
				a.weight( vclass, ucost );

				// tentative costs
				var tdist = v.dist + a.dist;
				var ttime = v.time + a.time;
				var ttoll = v.toll + a.toll;
				var tcost = ucost.userCost( tdist, ttime, ttoll );
				
				// destination endpoint of the arc is valid?
				// i.e. equal versions?
				if ( a.to.version != version ) { // no, reset it
					// if this is a new (previously unknown) vertex, then keepCosts
					// does not matter
					a.to.clearPath();
					a.to.clearCosts();
					a.to.version = version;
				}

				// arc relaxation
				if ( tcost < a.to.cost ) {
					a.to.dist = tdist;
					a.to.time = ttime;
					a.to.toll = ttoll;
					a.to.cost = tcost;
					a.to.est = tcost + hf(v,t,ucost);
					if ( a.to.parent == null )
						Q.add( a.to );
					else
						Q.update( a.to );
					a.to.parent = a;
				}
			}

		}

	}

	/* 
	 * Functional fold of the reverse path (or precedence list); if there is no
	 * path (no vertex found with parent set to itself), this method returns
	 * `first`
	 */
	@:generic
	public function revPathFold<T>( destination:Node, f:Arc->T->T, first:T ):T {
		var tv = getVertex( destination );
		var t = tv.version == version ? tv.parent : null;
		while ( t != null ) {
			first = f( t, first );
			if ( t.isPseudo() )
				return first;
			else
				t = t.from.version == version ? t.from.parent : null;
		}
		return first;
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
