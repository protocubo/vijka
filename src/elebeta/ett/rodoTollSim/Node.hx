package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class Node {

	public var id:Int;
	public var point:Point;

	public function toString() {
		return 'Node id: $id\n  => [lon lat]: [${point.rawString()}]';
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "point", TGeometry(TPoint) )
		];
	}

	public static function makeEmpty():Node {
		return new Node();
	}

	public static function make( id, point ):Node {
		var node = new Node();
		node.id = id;
		node.point = point;
		return node;
	}

	private function new() {}

}
