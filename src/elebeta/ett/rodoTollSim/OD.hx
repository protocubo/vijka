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
	public var originName:Null<String>;
	public var destinationName:Null<String>;
	public var tollWeight:Float; // always defined as 1., never exported

	public function toString() {
		var o = originName != null ? originName : "?";
		var d = destinationName != null ? destinationName : "?";
		return 'OD record \'$id\', of lot \'$lot\', on section \'$section\', on direction \'$direction\'\n'
		+'  => vehicle: $vehicleId, cargo: "$cargo", sample weight: $sampleWeight,\n'
		+'     cdist: $distWeight, ctime_o: $timeOperationalWeight, ctime_s: $timeSocialWeight,\n'
		+'     origin [lon lat ?name]: [${origin.rawString()} "$o"],\n'
		+'     destination [lon lat ?name]: [${destination.rawString()} "$d"]';
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
			new Field( "destination", TGeometry(TPoint) ),
			new Field( "originName", TNull(TString) ),
			new Field( "destinationName", TNull(TString) )
		];
	}

	public static function make( id, lot, section, direction, vehicleId, cargo
	, distWeight, timeOperationalWeight, timeSocialWeight, sampleWeight
	, origin, destination, ?originName, ?destinationName ):OD {
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
		od.originName = originName;
		od.destinationName = destinationName;
		return od;
	}

	private function new() { tollWeight = 1.; }

}
