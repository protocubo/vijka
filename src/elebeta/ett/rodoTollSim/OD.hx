package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class OD {

	public var id:Int;
	public var lot:Int;
	public var section:Int;
	public var direction:Int;
	public var vehicleId:Int;
	public var loadType:Null<String>;
	public var distWeight:Float;
	public var timeOperationalWeight:Float;
	public var timeSocialWeight:Float;
	public var sampleWeight:Float;
	public var origin:Point;
	public var destination:Point;

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
			new Field( "loadType", TNull(TString) ),
			new Field( "distWeight", TFloat ),
			new Field( "timeOperationalWeight", TFloat ),
			new Field( "timeSocialWeight", TFloat ),
			new Field( "sampleWeight", TFloat ),
			new Field( "origin", TGeometry(TPoint) ),
			new Field( "destination", TGeometry(TPoint) )
		];
	}

	public static function make( id, lot, section, direction, vehicleId, loadType
	, distWeight, timeOperationalWeight, timeSocialWeight, sampleWeight
	, origin, destination ):OD {
		var od = new OD();
		od.id = id;
		od.lot = lot;
		od.section = section;
		od.direction = direction;
		od.vehicleId = vehicleId;
		od.loadType = loadType;
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
