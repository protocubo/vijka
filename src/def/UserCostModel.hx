package def;

/* 
 * User perception of costs model.
 * 
 * The user perceives three types of costs:
 * . One associated with distance.
 * . One associated with time.
 * . Tolls.
 * 
 * userCost = [a]*distance + ( [b_social] + [b_operational] )*time + [c]*tolls
 *
 * Changing [c] to 0. can be used to disable toll sensitivity.
 */
class UserCostModel {

	/* 
	 * Cost per distance. Includes operational cost.
	 */
	public var a( default, null ):DistCostMultiplier;

	/* 
	 * Social cost per time.
	 */
	public var b_social( default, null ):TimeCostMultiplier;

	/* 
	 * Operational cost per time.
	 */
	public var b_operational( default, null ):TimeCostMultiplier;

	/* 
	 * Sensitivity to tolls. Defaults to 1.0.
	 */
	public var c( default, null ):TollSensitivity;

	/* 
	 * New user perception of costs model.
	 * The sensitivity to tolls defaults to 1.0.
	 */
	public function new( _a, _b_social, _b_operational, ?_c=1. ) {
		a = _a;
		b_social = _b_social;
		b_operational = _b_operational;
		c = _c;
	}

	/* 
	 * User cost (in $). If any part of the cost is mathematically indefinite
	 * , the returned cost will be Math.POSITIVE_INFINITY.
	 */
	public inline function userCost( dist:Dist, time:Time, toll:Toll ):Cost {
		var ucost = a*dist + ( b_social + b_operational )*time + c*toll;
		return Math.isNaN( ucost ) ? Math.POSITIVE_INFINITY : ucost;
	}

}

/* 
 * Cost/distance.
 */
abstract DistCostMultiplier( Float ) from Float to Float {
	@:op( A*B ) public static function multi( a:DistCostMultiplier, b:Dist ):Cost;
}

/* 
 * Cost/time.
 */
abstract TimeCostMultiplier( Float ) from Float to Float {
	@:op( A*B ) public static function multi( a:TimeCostMultiplier, b:Time ):Cost;

	@:op( A+B ) public static function add( a:TimeCostMultiplier, b:TimeCostMultiplier ):TimeCostMultiplier;
}

/* 
 * Toll sensitivity.
 */
abstract TollSensitivity( Float ) from Float to Float {
	@:op( A*B ) public static function multi( a:TollSensitivity, b:Toll ):Cost;
}

