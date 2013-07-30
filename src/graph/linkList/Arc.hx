package graph.linkList;

import def.*;

@:allow( graph.linkList.Digraph )
class Arc {

	// entity
	public var link( default, null ):Link;
	
	// relation
	public var from( default, null ):Vertex;
	public var to( default, null ):Vertex;

	function new( _from, _to, _link ) {
		link = _link;
		from = _from;
		to = _to;
	}

	public inline function time( vclass:VehicleClass ):Time {
		var speed = link.speed.get( vclass );
		return speed != null ? link.dist/speed : Math.POSITIVE_INFINITY;
	}

	public inline function toll( tollMulti:Float ):Toll {
		return link.toll != null ? link.toll*tollMulti : 0.;
	}

	public inline function isPseudo():Bool {
		return from == to && link == null;
	}

}
