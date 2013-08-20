package elebeta.ett.rodoTollSim;

import format.ett.Data;

class Vehicle {
	public var id:Int;
	public var noAxis:Int;
	public var tollMulti:Float;
	public var eqNo:Float;
	public var name:Null<String>;

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "noAxis", TInt ),
			new Field( "tollMulti", TFloat ),
			new Field( "eqNo", TFloat ),
			new Field( "name", TNull(TString) )
		];
	}

	public static function makeEmpty():Vehicle {
		return new Vehicle();
	}

	public static function make( id, noAxis, tollMulti, eqNo, ?name ):Vehicle {
		var veh = new Vehicle();
		veh.id = id;
		veh.noAxis = noAxis;
		veh.tollMulti = tollMulti;
		veh.eqNo = eqNo;
		veh.name = name;
		return veh;
	}

	private function new() {}

}