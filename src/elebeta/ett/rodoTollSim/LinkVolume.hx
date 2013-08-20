package elebeta.ett.rodoTollSim;

import format.ett.Data;

class LinkVolume {

	public var linkId:Int;
	public var vehicles:Int;
	public var axis:Int;
	public var tolls:Float;
	public var equivalentVehicles:Float;

	public static function ettFields():Array<Field> {
		return [
			new Field( "linkId", TInt ),
			new Field( "vehicles", TInt ),
			new Field( "axis", TInt ),
			new Field( "tolls", TFloat ),
			new Field( "equivalentVehicles", TFloat )
		];
	}

	public static function makeEmpty():LinkVolume {
		return new LinkVolume();
	}

	public static function make( linkId, vehicles, axis, tolls, equivalentVehicles ):LinkVolume {
		var vol = new LinkVolume();
		vol.linkId = linkId;
		vol.vehicles = vehicles;
		vol.axis = axis;
		vol.tolls = tolls;
		vol.equivalentVehicles = equivalentVehicles;
		return vol;
	}

	private function new() {}

}
