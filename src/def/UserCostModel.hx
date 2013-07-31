package def;

/* 
 * User perception of costs model.
 * 
 * The user perceives three types of costs:
 * . One associated with distance.
 * . One associated with time.
 * . Tolls.
 * 
 * userCost = [a]*distance + ( [b_social] + [b_operational] )*time + tolls
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
	 * New user perception of costs model.
	 */
	public function new( _a, _b_social, _b_operational ) {
		a = _a;
		b_social = _b_social;
		b_operational = _b_operational;
	}

	/* 
	 * User cost (in $).
	 */
	public inline function userCost( dist:Dist, time:Time, toll:Toll ):Cost {
		var ucost = a*dist + ( b_social + b_operational )*time + toll;
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
