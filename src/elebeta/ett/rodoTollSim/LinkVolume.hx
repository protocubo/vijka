package elebeta.ett.rodoTollSim;

import format.ett.Data;

class LinkVolume {

	public var linkId:Int;
	public var vehicles:Float;
	public var axis:Float;
	public var tolls:Float;
	public var equivalentVehicles:Float;

	public function sum( _vehicles, _axis, _tolls, _equivalentVehicles ) {
		vehicles += _vehicles;
		axis += _axis;
		tolls += _tolls;
		equivalentVehicles += _equivalentVehicles;
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "linkId", TInt ),
			new Field( "vehicles", TFloat ),
			new Field( "axis", TFloat ),
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
