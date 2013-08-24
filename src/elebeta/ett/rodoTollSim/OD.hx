package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class OD {

	public var id:Int;
	public var lot:Int;
	public var section:Int;
	public var direction:Int;
	public var vehicleId:Int;
	public var cargo:Null<String>;
	public var distWeight:Float;
	public var timeOperationalWeight:Float;
	public var timeSocialWeight:Float;
	public var sampleWeight:Float;
	public var origin:Point;
	public var destination:Point;

	public function toString() {
		return 'OD record \'$id\', of lot \'$lot\', on section \'$section\', on direction \'$direction\'\n'
		+'  => vehicle: $vehicleId, cargo: "$cargo", sample weight: $sampleWeight\n'
		+'     cdist: $distWeight, ctime_o: $timeOperationalWeight, ctime_s: $timeSocialWeight\n'
		+'     origin [lon lat]: [${origin.rawString()}], destination [lon lat]: [${destination.rawString()}]';
	}

	public static function makeEmpty():OD {
		return new OD();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "lot", TInt ),
			new Field( "section", TInt ),
			new Field( "direction", TInt ),
			new Field( "vehicleId", TInt ),
			new Field( "cargo", TNull(TString) ),
			new Field( "distWeight", TFloat ),
			new Field( "timeOperationalWeight", TFloat ),
			new Field( "timeSocialWeight", TFloat ),
			new Field( "sampleWeight", TFloat ),
			new Field( "origin", TGeometry(TPoint) ),
			new Field( "destination", TGeometry(TPoint) )
		];
	}

	public static function make( id, lot, section, direction, vehicleId, cargo
	, distWeight, timeOperationalWeight, timeSocialWeight, sampleWeight
	, origin, destination ):OD {
		var od = new OD();
		od.id = id;
		od.lot = lot;
		od.section = section;
		od.direction = direction;
		od.vehicleId = vehicleId;
		od.cargo = cargo;
		od.distWeight = distWeight;
		od.timeOperationalWeight = timeOperationalWeight;
		od.timeSocialWeight = timeSocialWeight;
		od.sampleWeight = sampleWeight;
		od.origin = origin;
		od.destination = destination;
		return od;
	}

	private function new() {}

}
