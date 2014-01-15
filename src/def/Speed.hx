package def;

/* 
 * Speed table for a link.
 */
class Speed {

	var values:Array<SpeedValue>;

	public function new() {
		values = [];
	}

	public function get( vclass:VehicleClass ):Null<SpeedValue> {
		return values[vclass.id];
	}

	public function set( vclass:VehicleClass, val:SpeedValue ):SpeedValue {
		return values[vclass.id] = val;
	}
	
}

abstract SpeedValue( Float ) from Float to Float {
	@:op( A+B ) public static function add( a:SpeedValue, b:SpeedValue ):SpeedValue;
}
