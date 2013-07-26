package def;

class Speed {

	var values:Array<SpeedValue>;

	public function new() {
		values = [];
	}

	public function get( vehicleClass:VehicleClass ):SpeedValue {
		return values[Type.enumIndex( vehicleClass )];
	}

	public function set( vehicleClass:VehicleClass, val:SpeedValue ):SpeedValue {
		return values[Type.enumIndex( vehicleClass )] = val;
	}
	
}

abstract SpeedValue( Float ) from Float to Float {
	@:op( A+B ) public static function add( a:SpeedValue, b:SpeedValue ):SpeedValue;
}
