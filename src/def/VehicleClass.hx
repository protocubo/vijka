package def;

/* 
 * Vehicle classes.
 */
class VehicleClass {

	public var id( get, never ):VehicleClassId;
	inline function get_id() return noAxis - 1; // this should be kept in the
	                                            // range [0...small_number]

	public var noAxis:AxisCount;
	
	public var tollMulti:TollMultiplier;
	
	public var equiv:EquivalentVehicles;
	
	public var name:String;

	public function new( _noAxis, _tollMulti, _equiv, _name ) {
		if ( _noAxis <= 0 )
			throw "#axis cannot be <= 0, for '#axis-1' is used for array indexing";
		noAxis = _noAxis;
		tollMulti = _tollMulti;
		equiv = _equiv;
		name = _name;
	}

	public inline function toString() return name;

}

/* 
 * Vehicle class identifier.
 */
abstract VehicleClassId( Int ) from Int to Int {

}

/* 
 * Vehicle axis count.
 */
abstract AxisCount( Int ) from Int to Int {

}

/* 
 * Vehicle toll base fare multiplier.
 */
abstract TollMultiplier( Float ) from Float to Float {

}

/* 
 * Vehicle equivalent number.
 */
abstract EquivalentVehicles( Float ) from Float to Float {

}
