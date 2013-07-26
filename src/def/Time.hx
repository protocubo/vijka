package def;

typedef Time = TimeValue;

abstract TimeValue( Float ) from Float to Float {
	@:op( A+B ) public static function add( a:TimeValue, b:TimeValue ):TimeValue;
}
