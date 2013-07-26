package def;

typedef Volume = VolumeValue;

abstract VolumeValue( Float ) from Float to Float {
	@:op( A+B ) public static function add( a:VolumeValue, b:VolumeValue ):VolumeValue {
		return cast( a, Float ) + cast( b, Float );
	}
}
