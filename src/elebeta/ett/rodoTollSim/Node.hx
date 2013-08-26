package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class Node {

	public var id:Int;
	public var point:Point;

	public inline function toString() {
		return 'Node id: $id\n  => [lon lat]: [${point.rawString()}]';
	}

	public inline function jsonBody():String {
		return '"id":$id';
	}

	public inline function geojsonGeometry():String {
		return point.geoJSONString();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "point", TGeometry(TPoint) )
		];
	}

	public static inline function makeEmpty():Node {
		return new Node();
	}

	public static inline function make( id, point ):Node {
		var node = new Node();
		node.id = id;
		node.point = point;
		return node;
	}

	private inline function new() {}

}
