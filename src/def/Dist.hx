package def;

import def.Speed;

typedef Dist = DistValue;

abstract DistValue( Float ) from Float to Float {
	@:op( A/B ) public static function compute( a:Dist, b:Time ):SpeedValue {
		return cast( a, Float )/cast( b, Float );
	}
}
