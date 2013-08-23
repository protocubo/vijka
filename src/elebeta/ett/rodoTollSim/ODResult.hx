package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class ODResult {

	public var odId:Int;
	public var weight:Float;
	public var ran:Bool;
	public var reached:Bool;
	public var dist:Null<Float>;
	public var time:Null<Float>;
	public var toll:Null<Float>;
	public var cost:Null<Float>;
	public var escaped:Null<Bool>;
	public var path:Null<Array<Int>>; // array of link ids

	public static function makeEmpty():ODResult {
		return new ODResult();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "odId", TInt ),
			new Field( "weight", TFloat ),
			new Field( "ran", TBool ),
			new Field( "reached", TBool ),
			new Field( "dist", TNull(TFloat) ),
			new Field( "time", TNull(TFloat) ),
			new Field( "toll", TNull(TFloat) ),
			new Field( "cost", TNull(TFloat) ),
			new Field( "escaped", TNull(TBool) ),
			new Field( "path", TNull(THaxeSerial) )
		];
	}

	public static function make( odId, weight, ran, reached, ?dist, ?time, ?toll, ?cost, ?escaped, ?path ):ODResult {
		var res = new ODResult();
		res.odId = odId;
		res.weight = weight;
		res.ran = ran;
		res.reached = reached;
		res.dist = dist;
		res.time = time;
		res.toll = toll;
		res.cost = cost;
		res.escaped = escaped;
		res.path = path;
		return res;
	}

	private function new() {}

}
