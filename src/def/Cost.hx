package def;

typedef Cost = CostValue;

abstract CostValue( Float ) from Float to Float {
	@:op( A+B ) public static function add( a:CostValue, b:CostValue ):Cost {
		return cast( a, Float ) + cast( b, Float );
	}
}
