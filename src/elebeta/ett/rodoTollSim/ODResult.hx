package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class ODResult {

	public var id:Int;
	public var escaped:Null<Bool>;
	public var path:Null<Array<Int>>; // array of link ids

	public static function makeEmpty():ODResult {
		return new ODResult();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "escaped", TNull(TBool) ),
			new Field( "path", TNull(THaxeSerial) )
		];
	}

	public static function make( id, ?escaped, ?path ):ODResult {
		var res = new ODResult();
		res.id = id;
		res.escaped = escaped;
		res.path = path;
		return res;
	}

	private function new() {}

}
