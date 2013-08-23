package elebeta.ett.rodoTollSim;

import format.ett.Data;
import sim.col.LinkTypeSpeedMap;

class LinkTypeSpeed implements LinkTypeSpeedMapKey {
	public var key:String;
	public var typeId:Int;
	public var vehicleId:Int;
	public var speed:Float;

	public static function ettFields():Array<Field> {
		return [
			new Field( "typeId", TInt ),
			new Field( "vehicleId", TInt ),
			new Field( "speed", TFloat )
		];
	}

	public static function makeEmpty():LinkTypeSpeed {
		return new LinkTypeSpeed();
	}

	public static function make( typeId, vehicleId, speed ):LinkTypeSpeed {
		var lts = new LinkTypeSpeed();
		lts.typeId = typeId;
		lts.vehicleId = vehicleId;
		lts.speed = speed;
		return lts;
	}

	private function new() {}

}
