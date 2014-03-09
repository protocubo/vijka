package def;

/* 
 * Vehicle classes.
 */
class VehicleClass {

	public var id:VehicleClassId;

	public var noAxis:AxisCount;
	
	public var tollMulti:TollMultiplier;
	
	public var equiv:EquivalentVehicles;
	
	public var name:String;

	public function new( _id, _noAxis, _tollMulti, _equiv, _name ) {
		if ( _id >= 16 )
			trace( "Vehicle _id "+_id+" is large, this may impact space performance" );
		id = _id;
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
abstract AxisCount( Float ) from Float to Float {
	@:op( A*B ) public static function scale( a:AxisCount, b:Float ):AxisCount;
}

/* 
 * Vehicle toll base fare multiplier.
 */
abstract TollMultiplier( Float ) from Float to Float {
	@:op( A*B ) public static function scale( a:TollMultiplier, b:Float ):TollMultiplier;
}

/* 
 * Vehicle equivalent number.
 */
abstract EquivalentVehicles( Float ) from Float to Float {
	@:op( A*B ) public static function scale( a:EquivalentVehicles, b:Float ):EquivalentVehicles;
}
