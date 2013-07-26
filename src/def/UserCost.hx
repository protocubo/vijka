package def;

class UserCost {
	public var a:DistCostMultiplier; // *distance, includes operational cost
	public var b:TimeCostMultiplier; // *time, time = distance/speed_user, (b_social + b_operational)

	public function new( _a, _b ) {
		a = _a;
		b = _b;
	}
}

abstract DistCostMultiplier( Float ) from Float to Float {
	@:op( A*B ) public static function multi( a:DistCostMultiplier, b:Dist ):Cost;
}

abstract TimeCostMultiplier( Float ) from Float to Float {
	@:op( A*B ) public static function multi( a:TimeCostMultiplier, b:Time ):Cost;
}
