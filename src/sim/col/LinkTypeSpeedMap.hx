package sim.col;

import elebeta.ett.rodoTollSim.*;

class LinkTypeSpeedMap {

	private var inner:Map<String,LinkTypeSpeed>;
	
	public function new() {
		inner = new Map();
	}

	public function set( k:LinkTypeSpeedMapKey, v:LinkTypeSpeed ):Void {
		var key = rekey(k);
		if ( k.key != key )
			k.key = key;
		inner.set( k.key, v );
	}

	public function get( k:LinkTypeSpeedMapKey ):Null<LinkTypeSpeed> {
		return inner.get( rekey(k) );
	}

	public function exists( k:LinkTypeSpeedMapKey ):Bool {
		return inner.exists( rekey(k) );
	}

	public function iterator():Iterator<LinkTypeSpeed> {
		return inner.iterator();
	}

	public static function rekey( k:LinkTypeSpeedMapKey ):String {
		return k.typeId+","+k.vehicleId;
	}

}

class TypeNVehicle implements LinkTypeSpeedMapKey {
	public var key:String;
	public var typeId:Int;
	public var vehicleId:Int;
	public function new( _typeId, _vehicleId ) {
		typeId  = _typeId;
		vehicleId = _vehicleId;
	}
}

interface LinkTypeSpeedMapKey {
	public var key:String;
	public var typeId:Int;
	public var vehicleId:Int;
}
