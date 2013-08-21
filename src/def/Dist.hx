package def;

import def.Speed;
import def.Time;

/* 
 * Distance in km.
 */
typedef Dist = DistValue;

abstract DistValue( Float ) from Float to Float {
	@:op( A/B ) public static function speed( a:DistValue, b:TimeValue ):SpeedValue;
	@:op( A/B ) public static function time( a:DistValue, b:SpeedValue ):TimeValue;

	@:op( A+B ) public static function add( a:DistValue, b:DistValue ):DistValue;
	@:op( A<B ) public static function lt( a:DistValue, b:DistValue ):Bool;
}
