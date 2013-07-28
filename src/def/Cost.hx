package def;

typedef Cost = CostValue;

abstract CostValue( Float ) from Float to Float {
	@:op( A*B ) public static function scale( a:CostValue, b:Float ):CostValue;
	
	@:op( A+B ) public static function add( a:CostValue, b:CostValue ):CostValue;
	@:op( A>B ) public static function gt( a:CostValue, b:CostValue ):Bool;
	@:op( A<B ) public static function lt( a:CostValue, b:CostValue ):Bool;
	@:op( A>=B ) public static function get( a:CostValue, b:CostValue ):Bool;
	@:op( A<=B ) public static function let( a:CostValue, b:CostValue ):Bool;
	@:op( A==B ) public static function eq( a:CostValue, b:CostValue ):Bool;
	@:op( A!=B ) public static function ne( a:CostValue, b:CostValue ):Bool;
}
