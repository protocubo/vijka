package elebeta.ett.vijka;

import format.ett.Data;

class LinkVolume {

	public var linkId:Int;
	public var vehicles:Float;
	public var axis:Float;
	public var tolls:Float;
	public var equivalentVehicles:Float;

	public function sum( v:LinkVolume ):Void {
		vehicles += v.vehicles;
		axis += v.axis;
		tolls += v.tolls;
		equivalentVehicles += v.equivalentVehicles;
	}

	public function sub( v:LinkVolume ):Void {
		vehicles -= v.vehicles;
		axis -= v.axis;
		tolls -= v.tolls;
		equivalentVehicles -= v.equivalentVehicles;
	}

	public function toString() {
		return 'Volume for link \'$linkId\'\n  '
		+'  => vehicles: $vehicles, axis: $axis, tolls: $tolls, equivalent vehicles: $equivalentVehicles';
	}

	public function jsonBody():String {
		return '"vehicles":$vehicles,"axis":$axis,"tolls":$tolls,"equivalentVehicles":$equivalentVehicles';
	}

	public function copy():LinkVolume {
		return make( linkId, vehicles, axis, tolls, equivalentVehicles );
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
