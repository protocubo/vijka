package def;

class LinkVolume {
	var values:Array<Volume>;

	public function new() {}

	public function get( vehicleClass:VehicleClass ):Volume {
		var v = values[Type.enumIndex( vehicleClass )];
		if ( v == null )
			v = 0.;
		return v;
	}

	public function set( vehicleClass:VehicleClass, val:Volume ):Volume {
		return values[Type.enumIndex( vehicleClass )] = val;
	}

	public function add( vehicleClass:VehicleClass, val:Volume ):Volume {
		var v = values[Type.enumIndex( vehicleClass )];
		if ( v == null )
			v = 0.;
		return values[Type.enumIndex( vehicleClass )] = v + val;
	}

}
