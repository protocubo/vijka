package graph.adjLists;

import def.*;

class Arc {

	// entity
	public var link( default, null ):Link;
	
	// relation
	public var from( default, null ):Vertex;
	public var to( default, null ):Vertex;

	// cost cache
	public var dist( get, never ):Dist; // auto from link
	public var time( default, null ):Time;
	public var toll( default, null ):Toll;
	public var cost( default, null ):Cost;

	public inline function new( _from, _to, _link ) {
		link = _link;
		from = _from;
		to = _to;
	}

	public inline function clearState() {
		time = Math.POSITIVE_INFINITY;
		toll = Math.POSITIVE_INFINITY;
		cost = Math.POSITIVE_INFINITY;
	}

	public inline function isPseudo():Bool {
		return from == to && link == null;
	}

	public inline function weight( vclass:VehicleClass, ucost:UserCostModel ):Void {
		time = ftime( vclass );
		toll = ftoll( vclass.tollMulti );
		cost = ucost.userCost( dist, time, toll );
	}

	private inline function get_dist():Dist return link.dist;

	private inline function ftime( vclass:VehicleClass ):Time {
		var speed = link.speed.get( vclass );
		return speed != null ? link.dist/speed : Math.POSITIVE_INFINITY;
	}

	private inline function ftoll( tollMulti:Float ):Toll {
		return link.toll != null ? link.toll*tollMulti : 0.;
	}

}
