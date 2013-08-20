package sim.col;

import elebeta.ett.rodoTollSim.*;

class LinkTypeSpeedMap {

	private var inner:Map<String,LinkTypeSpeed>;
	
	public function new() {
		inner = new Map();
	}

	public function set( k:LinkTypeSpeedMapKey, v:LinkTypeSpeed ):Void {
		inner.set( reKey(k), v );
	}

	public function get( k:LinkTypeSpeedMapKey ):Null<LinkTypeSpeed> {
		return inner.get( reKey(k) );
	}

	public function exists( k:LinkTypeSpeedMapKey ):Bool {
		return inner.exists( reKey(k) );
	}

	public function iterator():Iterator<LinkTypeSpeed> {
		return inner.iterator();
	}

	private static function reKey( k:LinkTypeSpeedMapKey ):String {
		return k.typeId+":"+k.vehicleId;
	}

}

class TypeNVehicle implements LinkTypeSpeedMapKey {
	public var typeId:Int;
	public var vehicleId:Int;
	public function new( _typeId, _vehicleId ) {
		typeId  = _typeId;
		vehicleId = _vehicleId;
	}
}

interface LinkTypeSpeedMapKey {
	public var typeId:Int;
	public var vehicleId:Int;
}
