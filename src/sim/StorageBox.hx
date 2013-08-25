package sim;

import elebeta.ett.rodoTollSim.*;

import Lambda.array;

class StorageBox {
	
	private var rs:Array<ODResult>;
	private var vs:Null<Array<LinkVolume>>;

	public function new( _key, _results:Iterable<ODResult>
	, _volumes:Iterable<LinkVolume>, deletePaths:Bool ) {
		key = _key;
		rs = [];
		for ( r in _results ) {
			r.key = key;
			if ( deletePaths )
				r.path = null;
			rs.push( r );
		}
		vs = _volumes != null ? array( _volumes ) : null;
	}

	public var key(default,null):String;

	public function results():Iterable<ODResult> {
		return rs;
	}

	public function volumes():Null<Iterable<LinkVolume>> {
		return vs;
	}

	public function countResults() return rs.length;
	
	public function countVolumes() return vs.length;

}
