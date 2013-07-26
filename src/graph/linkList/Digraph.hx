package graph.linkList;

import def.UserCost;
import def.VehicleClass;
import def.Dist;
import def.Time;

import def.Node;
import def.Link;

class Digraph {

	var arcs:Array<Arc>;

	var vertices:Map<Int,Vertex>;
	var arcIndex:Map<Int,Arc>;
	
	public function new() {
		arcs = [];
		vertices = new Map();
		arcIndex = new Map();
	}

	public function addVertex( node:Node ):Vertex {
		if ( vertices.exists( node.id ) )
			return vertices.get( node.id );
		else {
			var v = new Vertex( node );
			vertices.set( node.id, v );
			return v;
		}
	}

	public function getVertex( node:Node ) {
		return vertices.get( node.id );
	}

	public function addArc( link:Link ):Arc {
		if ( arcIndex.exists( link.id ) )
			return arcIndex.get( link.id );
		else {
			var v = getVertex( link.start );
			var w = getVertex( link.finish );
			var a = new Arc( v, w, link );
			arcIndex.set( link.id, a );
			arcs.push( a );
			return a;
		}
	}

	public function getArc( link:Link ) {
		return arcIndex.get( link.id );
	}

	public function spt( origin:Node, vclass:VehicleClass, ucost:UserCost, ?selectedToll:Link ) {
		clearState();
		
		var from = getVertex( origin );
		from.dist = 0.;
		from.time = 0.;
		from.cost = 0.;
		from.toll = 0.;
		from.parent = from;

		for ( v in vertices )
			for ( a in arcs )
				relax( a, vclass, ucost, selectedToll );
	}

	inline function relax( a:Arc, vclass:VehicleClass, ucost:UserCost, selectedToll:Link ) {
		if ( a.from.parent == null ) {
			// nothing to do, link not reached yet
		}
		else {
			var tdist = a.from.dist + a.link.dist;
			var ttime = a.from.time + a.link.dist/a.link.speed.get( vclass );
			var ttoll = a.from.toll + ( a.link.toll != null ? a.link.toll : 0. );
			var tcost = a.from.cost + userCost( ucost, tdist, ttime )
			+ ( a.link.toll != null ? a.link.toll : 0. );

			if ( a.to.parent == null || a.to.cost > tcost ) {
				a.to.parent = a.from;
				a.to.dist = tdist;
				a.to.time = ttime;
				a.to.cost = tcost;
				a.to.toll = ttoll;
				if ( selectedToll != null && a.link == selectedToll )
					a.to.selectedToll = true;
			}
		}
	}

	inline function userCost( ucost:UserCost, dist:Dist, time:Time ) {
		return ucost.a*dist + ucost.b*time;
	}

	function clearState() {
		for ( v in vertices )
			v.clearState();
	}

}
